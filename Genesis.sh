#!/bin/bash

# --- Colors & Styles ---
RCol='\e[0m'; BGre='\e[1;32m'; BYel='\e[1;33m'; BRed='\e[1;31m'; BBlu='\e[1;34m'; BPUR='\e[1;35m'; BWhI='\e[1;37m'; Grey='\e[0;38m'; BCY='\e[1;36m'

# --- Helper Functions ---
update_env() {
    local key=$1
    local val=$2
    if ! grep -q "$key" /etc/environment; then
        echo "$key=$val" | sudo tee -a /etc/environment > /dev/null
    fi
}

print_banner() {
    clear
    echo -e "${BPUR}[#]: SEED OF EXPANSION ${RCol} PROTOCOL: ${BRed}GENESIS${RCol}"
	#echo -e "" #
}

print_protocol() {
    echo -e "${Grey}────────────────────────────────────────${RCol}"
    #echo -e "[>]: PROTOCOL: ${BRed}GENESIS${RCol}"
	#echo -e "" #
}

setup_zsh() {
    echo -e "${BBlu}[*]: Setting up ZSH...${RCol}"
    sudo apt install zsh zsh-autosuggestions zsh-syntax-highlighting tree -y
    if [[ "$CONFIRM_KALI" == "y" ]]; then
        curl -sL "https://raw.githubusercontent.com/I-am-Providence/Genesis/main/zshrc" | tr -d '\r' > "$HOME/.zshrc"
        chown $USER:$USER "$HOME/.zshrc"
    fi
    sudo chsh -s $(which zsh) $USER
}

install_jellyfin() {
    echo -e "${BPUR}[*]: Starting Jellyfin Installation (Requires manual confirmation)...${RCol}"
    curl -s https://repo.jellyfin.org/install-debuntu.sh -o install-jellyfin.sh
    sudo bash install-jellyfin.sh
    rm install-jellyfin.sh
    if id "jellyfin" &>/dev/null; then
        sudo usermod -aG "$USER" jellyfin
        chmod 750 "/home/$USER"
        sudo flatpak override --filesystem=/usr/share/icons:ro 2>/dev/null
    fi
}

apply_kde_tweaks() {
    echo -e "${BBlu}[*]: Applying KDE tweaks...${RCol}"
    sudo apt install -y bibata-cursor-theme
    sudo apt install -y --no-install-recommends nemo
    gsettings set org.nemo.desktop show-desktop-icons false 2>/dev/null
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
}

apply_gnome_tweaks() {
    echo -e "${BBlu}[*]: Applying GNOME tweaks...${RCol}"
    sudo apt install -y gufw gnome-tweaks bibata-cursor-theme
    sudo apt install -y --no-install-recommends nemo
    gsettings set org.nemo.desktop show-desktop-icons false 2>/dev/null
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
}

# --- 1. PRE-INSTALLATION QUERIES (Collecting Intent) ---
if ! command -v fzf >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y fzf
fi

print_banner
print_protocol
echo -e "${BYel}[>]: Select installation type:${RCol}"
#echo -e "──────────────────────────────"
MODE=$(echo -e "[  CANCEL & EXIT  ]\n───────────────────\n[ LOCAL COMPUTER  ]\n[ VIRTUAL MACHINE ]\n[ SERVER (DEBIAN) ]" | fzf --height 15% --reverse --border)

[[ "$MODE" == *CANCEL* ]] && exit 0

# ALL types:
print_banner
print_protocol
echo -e "${BWhI}[>]: Select additional options:${RCol}"
#echo -e "────────────────────────────────"
tcflush /dev/tty in 2>/dev/null
echo -en "${BGre}[?]: Log in to Tailscale with authkey? (y/n): ${RCol}"
read -n 1 CONFIRM_TS < /dev/tty; echo
if [[ "$CONFIRM_TS" == "y" ]]; then
    echo -e "${BYel}[*]: Paste your authkey (or the whole command):${RCol}"
    read -r TS_KEY < /dev/tty
fi

# Only local and vm (not server):
if [[ "$MODE" != *SERVER* ]]; then
    tcflush /dev/tty in 2>/dev/null
    echo -en "${BRed}[?]: Enable Firewall (ufw)? (y/n): ${RCol}"
    read -n 1 CONFIRM_UFW < /dev/tty; echo

    echo -en "${BYel}[?]: Install ZSH? (y/n): ${RCol}"
    read -n 1 CONFIRM_ZSH < /dev/tty; echo
    [[ "$CONFIRM_ZSH" == "y" ]] && { echo -en "${BCY}[?]: Apply Kali-style .zshrc config? (y/n): ${RCol}"; read -n 1 CONFIRM_KALI < /dev/tty; echo; }

    echo -en "${BPUR}[?]: Install Jellyfin? (y/n): ${RCol}"
    read -n 1 CONFIRM_JELLY < /dev/tty; echo
       
    echo -en "${BBlu}[?]: Apply custom DE tweaks (Gnome|KDE)? (y/n): ${RCol}"
    read -n 1 CONFIRM_TWEAKS < /dev/tty; echo    
    if [[ "$CONFIRM_TWEAKS" == "y" ]]; then
        TWEAK_CHOICE=$(echo -e "[ GNOME DE ]\n[  KDE DE  ]\n[  CANCEL  ]" | fzf --height 10% --reverse --border --header="Choose your desktop environment:")
    fi
else
    CONFIRM_UFW="n"
fi

# --- 2. EXECUTION PHASE ---
print_banner
print_protocol

# JELLYFIN FIRST (to respect its manual confirmation prompt)
if [[ "$CONFIRM_JELLY" == "y" ]]; then
    install_jellyfin
fi

case "$MODE" in
    "[ SERVER (DEBIAN) ]")
        echo -e "[$]: MODE: ${BYel}SERVER (DEBIAN) ${RCol}\n"
        for dir in "/Polaris" "/Colosseum" "/Ark" "/Ark/Backups"; do sudo mkdir -p "$dir" && sudo chown -R $USER:$USER "$dir"; done
        sudo apt update
        sudo apt install -y python3 fzf rsync tar curl openssh-server ncdu tree transmission-daemon acl bc jq rename iptables-persistent screen
        ;;

    "[ VIRTUAL MACHINE ]"|"[ LOCAL COMPUTER  ]")
        [[ "$MODE" == *"VIRTUAL"* ]] && COL="${BBlu}" || COL="${BGre}"
        echo -e "[$]: MODE: ${COL}${MODE}${RCol}\n"
        
        for dir in "/Yggdrasil" "/Ark" "/Ark/Backups"; do sudo mkdir -p "$dir" && sudo chown -R $USER:$USER "$dir"; done
        sudo mkdir -p "/mnt/Bifrost" && sudo chown $USER:$USER "/mnt/Bifrost"
        
        sudo apt update
        COMMON_APPS="ufw python3 fzf rsync tar curl openssh-server transmission-remote-gtk tree ncdu vlc fuse3 qt5ct qt5-style-plugins jq bc rename git screen"
        [[ "$MODE" == *"LOCAL"* ]] && COMMON_APPS="$COMMON_APPS qbittorrent flatpak"
        sudo apt install -y $COMMON_APPS
        
        sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
        update_env "QT_QPA_PLATFORMTHEME" "qt5ct"
        update_env "QT_LOGGING_RULES" "\"qt.svg*.warning=false\""
        [[ "$MODE" == *"VIRTUAL"* ]] && sudo usermod -aG vboxsf $USER
        
        curl -fsS https://dl.brave.com/install.sh | sh
        ;;
esac

# Common Network Software
curl https://rclone.org/install.sh | sudo bash
curl -fsSL https://tailscale.com/install.sh | sh

# Configs based on collected answers
[[ "$CONFIRM_UFW" == "y" ]] && { sudo ufw allow 22/tcp; sudo ufw allow 8096/tcp; sudo ufw enable; }

if [[ -n "$TS_KEY" ]]; then
    if [[ "$TS_KEY" == *"tailscale up"* ]]; then sudo $TS_KEY; else sudo tailscale up --authkey "$TS_KEY"; fi
fi

[[ "$CONFIRM_ZSH" == "y" ]] && setup_zsh

if [[ "$CONFIRM_TWEAKS" == "y" ]]; then
    [[ "$TWEAK_CHOICE" == *"GNOME"* ]] && apply_gnome_tweaks
    [[ "$TWEAK_CHOICE" == *"KDE"* ]] && apply_kde_tweaks
fi

echo -e "${BCY}[*]: Upgrading...${RCol}"
sudo apt update && sudo apt full-upgrade -y

# --- Final Phase ---
tcflush /dev/tty in 2>/dev/null
echo -e "\n${BGre}[#]: DONE. Genesis finished.${RCol}"

if [ -f "./Expansion.py" ]; then
    echo -en "${BYel}[?]: Launch Expansion Protocol? (y/n): ${RCol}"
    read -n 1 confirm_exp < /dev/tty; echo
    if [[ "$confirm_exp" == "y" ]]; then
        chmod +x ./Expansion.py
        python3 ./Expansion.py
    else
        echo -e "${Grey}[!]: Expansion Protocol skipped.${RCol}"
    fi
else
    echo -e "${BRed}[X]:${RCol} ERROR. Expansion.py not found."
fi

# --- Keep terminal open for log review ---
while read -r -t 0; do read -r -n 1; done 2>/dev/null
echo -e "\n${BWhI}  ${RCol}"
echo -e "${BYel}[!]: Press any key to exit terminal.${RCol}"
read -rsn 1 < /dev/tty

exit 0

