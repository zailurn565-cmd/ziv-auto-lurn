import logging
import subprocess
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, ContextTypes

# ==========================================
# ဤနေရာတွင် သင့်အချက်အလက်များ ထည့်ပါ
# ==========================================
BOT_TOKEN = "8688887134:AAHfJ637at4au3zVuRa5oqbGE-UzzgGbkdc" 
ADMIN_ID = 7260224601  # သင့် Telegram ID ဂဏန်းကို ဒီမှာထည့်ပါ

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ADMIN_ID:
        await update.message.reply_text("⛔ သင်သည် ဤ Bot ကို အသုံးပြုခွင့် မရှိပါ။")
        return
    keyboard = [
        [InlineKeyboardButton("👤 Account ဖန်တီးရန်", callback_data='create_user')],
        [InlineKeyboardButton("❌ Account ဖျက်ရန်", callback_data='delete_user')],
        [InlineKeyboardButton("📊 Server Status", callback_data='server_status')]
    ]
    await update.message.reply_text("=== ZIVPN Style Bot Menu ===", reply_markup=InlineKeyboardMarkup(keyboard))

async def button_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    if query.data == 'server_status':
        uptime = subprocess.getoutput("uptime -p")
        ram = subprocess.getoutput("free -h | awk '/^Mem:/ {print $3\"/\"$2}'")
        text = f"📊 **Server Status**\n\n⏱ Uptime: {uptime}\n🧠 RAM: {ram}"
        await query.edit_message_text(text, parse_mode='Markdown')
    elif query.data == 'create_user':
        await query.edit_message_text("ပုံစံ - `/create username password days`\nဥပမာ - `/create user1 1234 30`", parse_mode='Markdown')
    elif query.data == 'delete_user':
        await query.edit_message_text("ပုံစံ - `/delete username`", parse_mode='Markdown')

async def create_user(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ADMIN_ID: return
    try:
        username, password, days = context.args[0], context.args[1], context.args[2]
        subprocess.run(f"useradd -e `date -d '{days} days' +'%Y-%m-%d'` -s /bin/false -M {username}", shell=True)
        subprocess.run(f"echo '{username}:{password}' | chpasswd", shell=True)
        await update.message.reply_text(f"✅ Account ဖန်တီးပြီးပါပြီ\n👤 User: `{username}`\n🔑 Pass: `{password}`\n📅 ရက်: {days}", parse_mode='Markdown')
    except IndexError:
        await update.message.reply_text("❌ ပုံစံမှားနေပါတယ်။")

async def delete_user(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != ADMIN_ID: return
    try:
        username = context.args[0]
        subprocess.run(f"userdel -r {username}", shell=True)
        await update.message.reply_text(f"✅ Account `{username}` ဖျက်ပြီးပါပြီ။", parse_mode='Markdown')
    except IndexError:
        await update.message.reply_text("❌ ပုံစံမှားနေပါတယ်။")

def main():
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("create", create_user))
    app.add_handler(CommandHandler("delete", delete_user))
    app.add_handler(CallbackQueryHandler(button_handler))
    app.run_polling()

if __name__ == '__main__':
    main()