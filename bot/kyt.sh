#!/bin/bash

# ====== Konfigurasi Password 7z ======
PASS_BOT="@Peyx"
PASS_KYT="@Peyx"
# ======================================

# Ambil data server
NS=$(cat /etc/xray/dns 2>/dev/null)
PUB=$(cat /etc/slowdns/server.pub 2>/dev/null)
domain=$(cat /etc/xray/domain 2>/dev/null)
grenbo="\e[92;1m"
NC='\e[0m'

# Membersihkan lock apt
echo -e "[INFO] Membersihkan lock file APT..."
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/dpkg/statoverride
dpkg --configure -a

# Hapus service lama
echo -e "[INFO] Menghapus service lama..."
systemctl stop kyt 2>/dev/null
rm -f /etc/systemd/system/kyt.service
rm -rf /usr/bin/kyt /usr/bin/bot /usr/bin/kyt.* /usr/bin/bot.* /root/kyt.7z /root/bot.7z /usr/bin/venv

# Install paket penting
echo -e "[INFO] Update dan install package penting..."
apt update && apt upgrade -y
apt install -y p7zip-full neofetch python3 python3-pip git wget curl figlet lolcat software-properties-common
apt install -y python3.12-venv

# Virtual environment
echo -e "[INFO] Membuat virtual environment Python..."
cd /usr/bin
python3 -m venv venv
source /usr/bin/venv/bin/activate
pip install --upgrade pip
pip install telethon paramiko

# Download & pasang bot
echo -e "[INFO] Download & pasang bot..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/bot.7z
if 7z t bot.7z -p"$PASS_BOT" >/dev/null 2>&1; then
    7z x bot.7z -p"$PASS_BOT" -y >/dev/null
    mv bot/* /usr/bin
    chmod +x /usr/bin/*
    rm -rf bot bot.7z
else
    echo -e "\e[91mPassword bot.7z salah atau file corrupt! Instalasi dibatalkan.\e[0m"
    exit 1
fi

# Download & pasang kyt
echo -e "[INFO] Download & pasang kyt..."
wget -q https://raw.githubusercontent.com/p3yx/newsc/main/bot/kyt.7z
if 7z t kyt.7z -p"$PASS_KYT" >/dev/null 2>&1; then
    7z x kyt.7z -p"$PASS_KYT" -o/usr/bin/ -y >/dev/null
    cd /usr/bin/kyt
    /usr/bin/venv/bin/pip install -r requirements.txt
else
    echo -e "\e[91mPassword kyt.7z salah atau file corrupt! Instalasi dibatalkan.\e[0m"
    exit 1
fi
cd
clear

# Tampilan
figlet "PEYX" | lolcat
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " \e[1;97;101m          ADD BOT PANEL          \e[0m"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "${grenbo}Tutorial Create Bot dan ID Telegram${NC}"
echo -e "${grenbo}[*] Buat Bot dan Token : @BotFather${NC}"
echo -e "${grenbo}[*] Cek ID Telegram : @MissRose_bot, perintah /info${NC}"
echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"

# Input data bot
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

# Info selesai
clear
echo -e "\e[92mInstalasi selesai!\e[0m"
echo "==============================="
echo "Token Bot     : $bottoken"
echo "Admin ID      : $admin"
echo "Domain        : $domain"
echo "==============================="
echo "Ketik /menu di Bot Telegram Anda"
