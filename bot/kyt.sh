#!/bin/bash

ZIP_PASS="Peyx23"  # Ganti dengan password file zip sebenarnya

# Warna
grenbo="\e[92;1m"
NC='\e[0m'

# Variabel konfigurasi
NS=$(cat /etc/xray/dns 2>/dev/null)
PUB=$(cat /etc/slowdns/server.pub 2>/dev/null)
domain=$(cat /etc/xray/domain 2>/dev/null)

echo -e "[INFO] Membersihkan lock file APT..."
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/dpkg/statoverride
dpkg --configure -a

echo -e "[INFO] Menghapus sisa installasi lama..."
systemctl stop kyt 2>/dev/null
rm -f /etc/systemd/system/kyt.service
rm -rf /usr/bin/kyt /usr/bin/bot /usr/bin/kyt.* /usr/bin/bot.* /usr/bin/venv /etc/bot
rm -rf bot.zip kyt.zip bot kyt

echo -e "[INFO] Update & install package penting..."
apt update && apt upgrade -y
apt install -y unzip neofetch python3 python3-pip git wget curl figlet lolcat software-properties-common p7zip-full
apt install -y python3.12-venv

echo -e "[INFO] Setup Python virtual environment..."
cd /usr/bin
python3 -m venv venv
source /usr/bin/venv/bin/activate
pip install --upgrade pip

echo -e "[INFO] Download dan ekstrak bot.zip..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/bot.zip -O bot.zip
7z x -p$ZIP_PASS bot.zip -obot -y >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[91m[ERROR] Gagal ekstrak bot.zip! Password salah atau file rusak.\e[0m"
  exit 1
fi
mv bot/* /usr/bin
chmod +x /usr/bin/*
rm -rf bot bot.zip

echo -e "[INFO] Download dan ekstrak kyt.zip..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/kyt.zip -O kyt.zip
7z x -p$ZIP_PASS kyt.zip -okyt -y >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[91m[ERROR] Gagal ekstrak kyt.zip! Password salah atau file rusak.\e[0m"
  exit 1
fi
mv kyt /usr/bin/kyt

echo -e "[INFO] Install dependensi dari requirements.txt..."
/usr/bin/venv/bin/pip install -r /usr/bin/kyt/requirements.txt
/usr/bin/venv/bin/pip install telethon paramiko

clear
figlet "PEYX" | lolcat
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m          ADD BOT PANEL          \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Create Bot dan ID Telegram${NC}"
echo -e "${grenbo}[*] Buat Bot dan Token : @BotFather${NC}"
echo -e "${grenbo}[*] Cek ID Telegram : @MissRose_bot, perintah /info${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Input Token dan ID
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

# Setup service systemd
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
echo -e "\e[92m[SELESAI] Bot berhasil diinstal dan dijalankan!\e[0m"
echo "==============================="
echo "Token Bot     : $bottoken"
echo "Admin ID      : $admin"
echo "Domain        : $domain"
echo "==============================="
echo "Ketik /menu di Bot Telegram Anda"
