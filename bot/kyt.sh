#!/bin/bash

NS=$(cat /etc/xray/dns 2>/dev/null)
PUB=$(cat /etc/slowdns/server.pub 2>/dev/null)
domain=$(cat /etc/xray/domain 2>/dev/null)
grenbo="\e[92;1m"
NC='\e[0m'

# Membersihkan dan persiapan sistem
echo -e "[INFO] Membersihkan lock file APT..."
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/dpkg/statoverride
dpkg --configure -a

echo -e "[INFO] Menghapus service lama..."
systemctl stop kyt 2>/dev/null
rm -f /etc/systemd/system/kyt.service
rm -rf /usr/bin/kyt /usr/bin/bot /usr/bin/kyt.* /usr/bin/bot.* /root/kyt.zip /root/bot.zip /usr/bin/venv

echo -e "[INFO] Update dan install package penting..."
apt update && apt upgrade -y
apt install -y unzip neofetch python3 python3-pip git wget curl figlet lolcat software-properties-common
apt install python3.12-venv

echo -e "[INFO] Membuat virtual environment Python..."
cd /usr/bin
python3 -m venv venv
source /usr/bin/venv/bin/activate
pip install --upgrade pip

# Fungsi unzip dengan verifikasi password
function unzip_with_password() {
  ZIPFILE="$1"
  DEST="$2"
  echo -e "[INFO] Menyiapkan ekstrak $ZIPFILE ke $DEST"

  while read password; do
    echo -ne "[*] Mencoba password: $password\r"
    unzip -P "$password" -o "$ZIPFILE" -d "$DEST" &>/dev/null
    if [ $? -eq 0 ]; then
      echo -e "\n[✓] Berhasil extract $ZIPFILE dengan password: $password"
      return 0
    fi
  done < passwords.txt

  echo -e "\n[✗] Gagal extract $ZIPFILE. Tidak ada password yang cocok."
  exit 1
}

# Download & unzip bot.zip
echo -e "[INFO] Download & pasang bot..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/bot.zip -O bot.zip
unzip_with_password "bot.zip" "bot"
mv bot/* /usr/bin
chmod +x /usr/bin/*
rm -rf bot bot.zip

# Download & unzip kyt.zip
echo -e "[INFO] Download & pasang kyt..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/kyt.zip -O kyt.zip
unzip_with_password "kyt.zip" "/usr/bin/"

# Install Python requirements
cd /usr/bin/kyt
/usr/bin/venv/bin/pip install -r requirements.txt
pip install telethon paramiko
cd

# Konfigurasi Bot
clear
figlet "PEYX" | lolcat
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m          ADD BOT PANEL          \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Create Bot dan ID Telegram${NC}"
echo -e "${grenbo}[*] Buat Bot dan Token : @BotFather${NC}"
echo -e "${grenbo}[*] Cek ID Telegram : @MissRose_bot, perintah /info${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -e -p "[*] Masukkan Bot Token Anda : " bottoken
read -e -p "[*] Masukkan ID Telegram Anda : " admin

mkdir -p /etc/bot
cat <<EOF > /usr/bin/kyt/var.txt
BOT_TOKEN="$bottoken"
ADMIN="$admin"
DOMAIN="$domain"
PUB="$PUB"
HOST="$NS"
EOF

echo "#bot# $bottoken $admin" > /etc/bot/.bot.db

# Buat service systemd
cat >/etc/systemd/system/kyt.service <<EOF
[Unit]
Description=App Bot kyt Service
After=network.target network-online.target systemd-user-sessions.service time-sync.target
Wants=network-online.target

[Service]
ExecStartPre=/bin/sleep 5
ExecStart=/bin/bash -c 'source /usr/bin/venv/bin/activate && python3 -m kyt'
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin:/usr/bin/venv/bin
Environment=PYTHONUNBUFFERED=1
EnvironmentFile=/usr/bin/kyt/var.txt
WorkingDirectory=/usr/bin
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now kyt

clear
echo -e "\e[92mInstalasi selesai!\e[0m"
echo "==============================="
echo "Token Bot     : $bottoken"
echo "Admin ID      : $admin"
echo "Domain        : $domain"
echo "==============================="
echo "Ketik /menu di Bot Telegram Anda"
