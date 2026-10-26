#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

while true; do
    clear
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}      ULTIMATE VPN MANAGEMENT MENU       ${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo -e " [1] SSH Account ဖန်တီးရန်"
    echo -e " [2] Service Status စစ်ရန်"
    echo -e " [3] အားလုံး Restart လုပ်ရန်"
    echo -e " [4] WireGuard QR Code ထုတ်ရန်"
    echo -e " [5] ထွက်ရန် (Exit)"
    echo -e "${BLUE}=========================================${NC}"
    read -p " ရွေးချယ်ပါ [1-5]: " opt

    case $opt in
        1)
           clear; read -p "Username: " uname; read -p "Password: " pass; read -p "ရက်အတွင်း (ဥပမာ 30): " days
           useradd -e `date -d "$days days" +"%Y-%m-%d"` -s /bin/false -M $uname
           echo -e "$pass\n$pass\n" | passwd $uname &> /dev/null
           echo -e "${GREEN}အကောင့်ဖန်တီးပြီးပါပြီ။${NC}"; read -p "Enter နှိပ်ပါ..." ;;
        2)
           clear; systemctl is-active dropbear stunnel4 xray wg-quick@wg0 badvpn; read -p "Enter နှိပ်ပါ..." ;;
        3)
           systemctl restart dropbear stunnel4 xray wg-quick@wg0 badvpn; echo -e "${GREEN}Restart ပြီးပါပြီ။${NC}"; sleep 2 ;;
        4)
           clear; qrencode -t ansiutf8 < /etc/wireguard/wg0.conf; read -p "Enter နှိပ်ပါ..." ;;
        5) exit 0 ;;
    esac
done