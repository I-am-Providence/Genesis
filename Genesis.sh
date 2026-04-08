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
    echo -e "${BPUR}[#]: SEED OF EXPANSION ${RCol}"
	echo -e "" #
}

print_protocol() {
    # echo -e "${Grey}--------------------------${RCol}"
    echo -e "[>]: PROTOCOL: ${BRed}GENESIS${RCol}"
	echo -e "" #
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



# --- Initialization ---
if ! command -v fzf >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y fzf
fi

print_banner
print_protocol
echo -e "${BYel}[?]: Select installation type:${RCol}"
MODE=$(echo -e "[  CANCEL & EXIT  ]\n───────────────────\n[ LOCAL COMPUTER  ]\n[ VIRTUAL MACHINE ]\n[ SERVER (DEBIAN) ]" | fzf --height 15% --reverse --border)

case "$MODE" in
    "[ SERVER (DEBIAN) ]")
        print_banner
		print_protocol
        echo -e "[$]: MODE: ${BYel}SERVER (DEBIAN) ${RCol}\n"

        # Structure
        for dir in "/Polaris" "/Colosseum" "/Ark" "/Ark/Backups"; do
            sudo mkdir -p "$dir" && sudo chown -R $USER:$USER "$dir"
        done

        # Software
        sudo apt update
        sudo apt install -y python3 fzf rsync tar curl openssh-server ncdu tree transmission-daemon acl bc jq rename iptables-persistent screen
        curl https://rclone.org/install.sh | sudo bash

        # Tailscale & Network
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo ufw allow 22/tcp
		
        # Firewall
		tcflush /dev/tty in 2>/dev/null
        echo -en "${BRed}[?]: Enable Firewall? (y/n): ${RCol}"
        read -n 1 confirm_ufw < /dev/tty; echo
        [[ "$confirm_ufw" == "y" ]] && sudo ufw enable

        # Optional Tailscale login
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BGre}[?]: Log in to Tailscale with authkey? (y/n): ${RCol}"
        read -n 1 confirm_tailscale < /dev/tty; echo
        if [[ "$confirm_tailscale" == "y" ]]; then
            echo -e "${BYel}[*]: Paste your authkey (or the whole command):${RCol}"
            read -r input_key < /dev/tty

            if [[ -n "$input_key" ]]; then
                if [[ "$input_key" == *"tailscale up"* ]]; then
                    sudo $input_key
                else
                    sudo tailscale up --authkey "$input_key"
                fi
            fi
        fi

        echo -e "${BCY}[*]: Upgrading...${RCol}"
        sudo apt upgrade -y
        ;;

    "[ VIRTUAL MACHINE ]")
        print_banner
		print_protocol
        echo -e "[$]: MODE: ${BBlu}VIRTUAL MACHINE ${RCol}\n"

        # Structure
        for dir in "/Yggdrasil" "/Ark" "/Ark/Backups"; do
            sudo mkdir -p "$dir" && sudo chown -R $USER:$USER "$dir"
        done
        for dir in "/mnt/Bifrost"; do
            sudo mkdir -p "$dir" && sudo chown $USER:$USER "$dir"
        done

        # Software
        sudo apt update
        sudo apt install -y python3 fzf rsync tar curl openssh-server transmission-remote-gtk tree ncdu vlc fuse3 qt5ct qt5-style-plugins jq bc rename git screen
        sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
        curl https://rclone.org/install.sh | sudo bash
        curl -fsS https://dl.brave.com/install.sh | sh

        # Tailscale & Network
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo ufw allow 22/tcp
        sudo ufw allow 8096/tcp

        # Fixes
        update_env "QT_QPA_PLATFORMTHEME" "qt5ct"
        update_env "QT_LOGGING_RULES" "\"qt.svg*.warning=false\""
		sudo usermod -aG vboxsf $USER

        # Media
        curl -s https://repo.jellyfin.org/install-debuntu.sh | sudo bash
        id "jellyfin" &>/dev/null && sudo usermod -aG $USER jellyfin && chmod 750 /home/$USER

        # Firewall
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BRed}[?]: Enable Firewall? (y/n): ${RCol}"
        read -n 1 confirm_ufw < /dev/tty; echo
        [[ "$confirm_ufw" == "y" ]] && sudo ufw enable

        # Optional Tailscale login
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BGre}[?]: Log in to Tailscale with authkey? (y/n): ${RCol}"
        read -n 1 confirm_tailscale < /dev/tty; echo
        if [[ "$confirm_tailscale" == "y" ]]; then
            echo -e "${BYel}[*]: Paste your authkey (or the whole command):${RCol}"
            read -r input_key < /dev/tty

            if [[ -n "$input_key" ]]; then
                if [[ "$input_key" == *"tailscale up"* ]]; then
                    sudo $input_key
                else
                    sudo tailscale up --authkey "$input_key"
                fi
            fi
        fi

		# Optional ZSH
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BPUR}[?]: Install ZSH? (y/n): ${RCol}"
        read -n 1 confirm_ZSH < /dev/tty; echo
        if [[ "$confirm_ZSH" == "y" ]]; then
            sudo apt install zsh zsh-autosuggestions zsh-syntax-highlighting tree -y

            echo -en "${BCY}[?]: Apply Kali-style .zshrc config? (y/n): ${RCol}"
            read -n 1 confirm_kali < /dev/tty; echo
            if [[ "$confirm_kali" == "y" ]]; then
                #echo -e "${Grey}[>]: Downloading Kali config...${RCol}"
                curl -sL "https://raw.githubusercontent.com/I-am-Providence/Genesis/main/zshrc" | tr -d '\r' > "$HOME/.zshrc"
                chown $USER:$USER "$HOME/.zshrc"
            fi

            sudo chsh -s $(which zsh) $USER
            echo -e "[#]: ZSH configured. Logout and login again to activate ZSH."
        fi

		# --- Tweaks Section ---
		tcflush /dev/tty in 2>/dev/null
		echo -en "${BCY}[?]: Apply custom DE tweaks (Gnome|KDE)? (y/n): ${RCol}"
		read -n 1 confirm_tweaks < /dev/tty; echo

		if [[ "$confirm_tweaks" == "y" ]]; then
			echo -e "${BBlu}[#]: Select Tweak Set:${RCol}"
			# Використовуємо fzf для красивого вибору (як і в основному меню)
			TWEAK_MODE=$(echo -e "[ GNOME DE ]\n[  KDE DE  ]\n[  CANCEL  ]" | fzf --height 10% --reverse --border --header="Choose your desktop environment:")

			case "$TWEAK_MODE" in
				*"GNOME"*)
					apply_gnome_tweaks
					;;
				*"KDE"*)
					apply_kde_tweaks
					;;
				*)
					echo -e "${Grey}[>]: Tweaks skipped.${RCol}"
					;;
			esac
		fi

        echo -e "${BCY}[*]: Upgrading...${RCol}"
        sudo apt upgrade -y
        ;;

    "[ LOCAL COMPUTER  ]")
        print_banner
		print_protocol
        echo -e "[$]: MODE: ${BGre}LOCAL COMPUTER ${RCol}\n"

        # Structure
        for dir in "/Yggdrasil" "/Ark" "/Ark/Backups"; do
            sudo mkdir -p "$dir" && sudo chown -R $USER:$USER "$dir"
        done
        for dir in "/mnt/Bifrost"; do
            sudo mkdir -p "$dir" && sudo chown $USER:$USER "$dir"
        done

        # Software
        sudo apt update
        sudo apt install -y python3 fzf rsync tar curl openssh-server transmission-remote-gtk ncdu tree vlc qbittorrent flatpak fuse3 qt5ct qt5-style-plugins jq bc rename git screen
        sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
        curl https://rclone.org/install.sh | sudo bash
        curl -fsS https://dl.brave.com/install.sh | sh

        # Tailscale & Network
        curl -fsSL https://tailscale.com/install.sh | sh
        sudo ufw allow 22/tcp
        sudo ufw allow 8096/tcp

        # Fixes
        update_env "QT_QPA_PLATFORMTHEME" "qt5ct"
        update_env "QT_LOGGING_RULES" "\"qt.svg*.warning=false\""

        # Media
        curl -s https://repo.jellyfin.org/install-debuntu.sh | sudo bash
        id "jellyfin" &>/dev/null && sudo usermod -aG $USER jellyfin && chmod 750 /home/$USER
        sudo flatpak override --filesystem=/usr/share/icons:ro 2>/dev/null

        # Firewall
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BRed}[?]: Enable Firewall? (y/n): ${RCol}"
        read -n 1 confirm_ufw < /dev/tty; echo
        [[ "$confirm_ufw" == "y" ]] && sudo ufw enable

        # Optional Tailscale login
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BGre}[?]: Log in to Tailscale with authkey? (y/n): ${RCol}"
        read -n 1 confirm_tailscale < /dev/tty; echo
        if [[ "$confirm_tailscale" == "y" ]]; then
            echo -e "${BYel}[*]: Paste your authkey (or the whole command):${RCol}"
            read -r input_key < /dev/tty

            if [[ -n "$input_key" ]]; then
                if [[ "$input_key" == *"tailscale up"* ]]; then
                    sudo $input_key
                else
                    sudo tailscale up --authkey "$input_key"
                fi
            fi
        fi

		# Optional ZSH
        tcflush /dev/tty in 2>/dev/null
        echo -en "${BPUR}[?]: Install ZSH? (y/n): ${RCol}"
        read -n 1 confirm_ZSH < /dev/tty; echo
        if [[ "$confirm_ZSH" == "y" ]]; then
            sudo apt install zsh zsh-autosuggestions zsh-syntax-highlighting tree -y

            echo -en "${BCY}[?]: Apply Kali-style .zshrc config? (y/n): ${RCol}"
            read -n 1 confirm_kali < /dev/tty; echo
            if [[ "$confirm_kali" == "y" ]]; then
                #echo -e "${Grey}[>]: Downloading Kali config...${RCol}"
                curl -sL "https://raw.githubusercontent.com/I-am-Providence/Genesis/main/zshrc" | tr -d '\r' > "$HOME/.zshrc"
                chown $USER:$USER "$HOME/.zshrc"
            fi

            sudo chsh -s $(which zsh) $USER
            echo -e "[#]: ZSH configured. Logout and login again to activate ZSH."
        fi

		# --- Tweaks Section ---
		tcflush /dev/tty in 2>/dev/null
		echo -en "${BBlu}[?]: Apply custom DE tweaks (Gnome|KDE)? (y/n): ${RCol}"
		read -n 1 confirm_tweaks < /dev/tty; echo

		if [[ "$confirm_tweaks" == "y" ]]; then
			echo -e "${BYel}[#]: Select Tweak Set:${RCol}"
			# Використовуємо fzf для красивого вибору (як і в основному меню)
			TWEAK_MODE=$(echo -e "[ GNOME DE ]\n[  KDE DE  ]\n[  CANCEL  ]" | fzf --height 10% --reverse --border --header="Choose your desktop environment:")

			case "$TWEAK_MODE" in
				*"GNOME"*)
					apply_gnome_tweaks
					;;
				*"KDE"*)
					apply_kde_tweaks
					;;
				*)
					echo -e "${Grey}[>]: Tweaks skipped.${RCol}"
					;;
			esac
		fi

        echo -e "${BCY}[*]: Upgrading...${RCol}"
        sudo apt upgrade -y
        ;;

    *)
        echo "Exiting..."
        exit 0
        ;;
esac

# --- Final Phase ---
echo -e "\n${BGre}[#]: DONE. Genesis finished.${RCol}"

# --- Keep terminal open for log review ---
while read -r -t 0; do read -r -n 1; done 2>/dev/null
echo -e "\n${BWhI}  ${RCol}"
echo -e "${BYel}[!]: Press any key to exit terminal.${RCol}"
read -rsn 1 < /dev/tty

exit 0
