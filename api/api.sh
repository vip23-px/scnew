#!/bin/bash
clear
green="\e[38;5;82m"
red="\e[38;5;196m"
neutral="\e[0m"
blue="\e[38;5;39m"
yellow="\e[38;5;226m"

setup_bot() {
    NODE_VERSION=$(node -v 2>/dev/null | grep -oP '(?<=v)\d+' || echo "0")
    rm -f /var/lib/dpkg/lock*
    rm -f /var/lib/dpkg/stato*

    if [ "$NODE_VERSION" -lt 22 ]; then
        echo -e "${yellow}Installing Node.js v22...${neutral}"
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
        apt-get install -y nodejs
        npm install -g npm@latest
    else
        echo -e "${green}Node.js v$NODE_VERSION is OK${neutral}"
    fi

    if [ ! -f /usr/bin/api-xwan/api.js ]; then
        echo -e "${yellow}Mengunduh API File...${neutral}"
        curl -sL "https://raw.githubusercontent.com/p3yx/newsc/main/api/api-xwan.zip" -o /usr/bin/api-xwan.zip
        cd /usr/bin
        7z x -punlock api-xwan.zip
        rm api-xwan.zip*
        chmod +x api-xwan/*
        cd
    fi

    npm install --prefix /usr/bin/api-xwan express child_process

    # AUTH KEY
    NEW_AUTH_KEY=$(openssl rand -hex 3)
    sed -i '/export AUTH_KEY=/d' /etc/profile
    echo "export AUTH_KEY=\"$NEW_AUTH_KEY\"" >> /etc/profile
    export AUTH_KEY="$NEW_AUTH_KEY"

    # Telegram Bot
    echo -e "${blue}Masukkan Token Bot Telegram Anda:${neutral}"
    read -rp "Token: " BOT_TOKEN
    echo -e "${blue}Masukkan Chat ID Telegram Anda:${neutral}"
    read -rp "Chat ID: " CHAT_ID

    echo "export KEYAPI=\"$BOT_TOKEN\"" >/etc/botapi.conf
    echo "export CHATID=\"$CHAT_ID\"" >>/etc/botapi.conf
    grep -q "botapi.conf" /etc/profile || echo "source /etc/botapi.conf" >> /etc/profile
    source /etc/botapi.conf

    SERVER_IP=$(curl -s ip.dekaa.my.id)
    DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "(Domain tidak ditemukan)")

    MESSAGE="🚀 *API-Peyx* 🚀
🔐 *Auth Key:* \`$AUTH_KEY\`
📡 *IP Server:* \`$SERVER_IP\`
🌐 *Domain:* \`$DOMAIN\`
📦 *Status API:* \`Memulai...\`"

    curl -s -X POST "https://api.telegram.org/bot$KEYAPI/sendMessage" \
        -d "chat_id=$CHATID" \
        -d "text=$MESSAGE" \
        -d "parse_mode=Markdown"

    echo -e "${green}✅ AUTH selesai & dikirim ke Telegram${neutral}"
}

server_app() {
    cat >/etc/systemd/system/apisellvpn.service <<EOF
[Unit]
Description=App Bot SellVPN
After=network.target

[Service]
ExecStart=/bin/bash /usr/bin/apisellvpn
Restart=always
User=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=/usr/bin

[Install]
WantedBy=multi-user.target
EOF

    cat >/usr/bin/apisellvpn <<EOF
#!/bin/bash
source /etc/profile
source /etc/botapi.conf
cd /usr/bin/api-xwan
node api.js
EOF

    chmod +x /usr/bin/apisellvpn

    CEK_PORT=$(lsof -i:5888 | awk 'NR>1 {print $2}' | sort -u)
    if [[ ! -z "$CEK_PORT" ]]; then
        echo "Menutup proses port 5888..."
        echo "$CEK_PORT" | xargs kill -9
    fi

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable apisellvpn
    systemctl restart apisellvpn

    sleep 2

    STATUS=$(systemctl is-active apisellvpn)
    echo -e "Status Service: ${STATUS}"

    curl -s -X POST "https://api.telegram.org/bot$KEYAPI/sendMessage" \
        -d "chat_id=$CHATID" \
        -d "text=🟢 *Service API aktif:* \`apisellvpn ($STATUS)\`" \
        -d "parse_mode=Markdown"

    echo -e "${green}✅ Service bot aktif di port 5888${neutral}"
    rm -f api.sh
}

setup_bot
server_app
