#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Run as root! (sudo su)${NC}"
   exit 1
fi

echo -e "${YELLOW}[*] System Update နဲ့ Packages များ Install လုပ်နေပါတယ်...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget sudo net-tools jq unzip git screen nano \
    dropbear stunnel4 openssl vnstat ufw fail2ban zip \
    wireguard qrencode iptables-persistent cmake build-essential \
    python3 python3-pip nginx -y

echo -e "${YELLOW}[*] SSH နဲ့ Dropbear ကို ပြင်ဆင်နေပါတယ်...${NC}"
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=143/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 109"/g' /etc/default/dropbear
systemctl restart dropbear

echo -e "${YELLOW}[*] Stunnel (TLS/SSL) ကို ပြင်ဆင်နေပါတယ်...${NC}"
openssl req -new -x509 -days 365 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=MM/ST=Yangon/L=Yangon/O=VPN/OU=IT/CN=localhost"
cat << 'EOF' > /etc/stunnel/stunnel.conf
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
[ssh]
accept = 443
connect = 127.0.0.1:143
EOF
systemctl restart stunnel4

echo -e "${YELLOW}[*] Xray Core ကို Install လုပ်နေပါတယ်...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

UUID=$(cat /proc/sys/kernel/random/uuid)
cat << EOF > /usr/local/etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    { "port": 10000, "protocol": "vmess", "settings": { "clients": [{ "id": "$UUID", "alterId": 0 }] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
    { "port": 10001, "protocol": "vless", "settings": { "clients": [{ "id": "$UUID" }], "decryption": "none" }, "streamSettings": { "network": "tcp" } }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
systemctl restart xray

echo -e "${YELLOW}[*] WireGuard VPN ကို ပြင်ဆင်နေပါတယ်...${NC}"
mkdir -p /etc/wireguard
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
chmod 600 /etc/wireguard/privatekey
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = 10.66.66.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
systemctl enable wg-quick@wg0 && systemctl start wg-quick@wg0

echo -e "${YELLOW}[*] BadVPN (UDP) ကို Install လုပ်နေပါတယ်...${NC}"
cd /usr/local/bin
wget -q https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.tar.gz
tar -xzf 1.999.130.tar.gz
cd badvpn-1.999.130
mkdir build && cd build
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
make > /dev/null 2>&1 && make install > /dev/null 2>&1
cd /usr/local/bin && rm -rf badvpn-1.999.130*

cat << 'EOF' > /etc/systemd/system/badvpn.service
[Unit]
Description=BadVPN UDPGW
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable badvpn && systemctl start badvpn

ufw allow 22/tcp && ufw allow 143/tcp && ufw allow 109/tcp && ufw allow 443/tcp && ufw allow 10000:10002/tcp && ufw allow 51820/udp && ufw allow 7300/tcp
echo "y" | ufw enable

# Bot နဲ့ Menu ကို သက်ဆိုင်ရာ နေရာမှာ ရွှေ့ခြင်း
mkdir -p /usr/local/etc/myvpn
if [ -f "./bot.py" ]; then
    cp bot.py /usr/local/etc/myvpn/bot.py
    cp menu.sh /usr/local/bin/menu
    chmod +x /usr/local/bin/menu
else
    echo -e "${RED}bot.py နဲ့ menu.sh ဖိုင်များ မတွေ့ရပါ။ ဒီ install.sh ရှိတဲ့ Folder ထဲမှာ ထည့်ထားဖို့ လိုပါတယ်။${NC}"
fi

# Bot Service ဖန်တီးခြင်း
cat << 'EOF' > /etc/systemd/system/myvpn-bot.service
[Unit]
Description=ZIVPN Style Telegram Bot
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/etc/myvpn/bot.py
Restart=always
[Install]
WantedBy=multi-user.target
EOF

pip3 install python-telegram-bot --break-system-packages
systemctl daemon-reload
systemctl enable myvpn-bot
systemctl start myvpn-bot

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN} တပ်ဆင်ခြင်း ပြီးစီးပါပြီ။ 'menu' လို့ ရိုက်ပြီး အသုံးပြုပါ။ ${NC}"
echo -e "${GREEN}=========================================${NC}"