#!/usr/bin/env sh 

set -o errexit
set -o pipefail

MY_USER=andre

readonly PACOTES=(
    "xdg-user-dirs" "vim" "telegram-desktop" "p7zip" 
    "zip" "unzip" "unrar" "wget" "numlockx" "polkit-gnome" "compton" "pamac-aur" 
    "google-chrome" "alsa-utils" "alsa-oss" "alsa-lib" "pulseaudio"
    "playerctl" "pavucontrol" "xorg-server" "xorg-xinit" "xorg-xprop" "xorg-xbacklight" 
    "xorg-xdpyinfo" "xorg-xrandr" "xf86-video-intel" "vulkan-intel" "network-manager-applet" 
    "networkmanager-pptp" "remmina" "rdesktop" "remmina-plugin-rdesktop" "ufw" "lightdm" 
    "lightdm-gtk-greeter" "lightdm-gtk-greeter-settings"
    "rofi" "dunst" "tty-clock"
    "gtk-engine-murrine" "lib32-gtk-engine-murrine" "hardcode-tray-git" 
    "ttf-liberation" "ttf-iosevka-ss07" "ttf-iosevka-term-ss09" "xclip" "visual-studio-code-bin"
    "xfce4" "xfce4-goodies" papirus-icon-theme-git papirus-folders-git gtk-theme-arc-grey-git)
    
function configurar_teclado(){
    localectl set-x11-keymap br abnt2
    localectl set-keymap br abnt2
    timedatectl set-local-rtc 1 --adjust-system-clock
}


function instalar_aur_helper(){
    pacman -S git --needed --noconfirm
    su ${MY_USER} -c "git clone https://aur.archlinux.org/yay.git /home/${MY_USER}/yay"
    cd "/home/${MY_USER}/yay"
    su ${MY_USER} -c "makepkg -si --noconfirm"
    cd ..
    rm -rf yay
}

function instalar_pacote(){
    for i in "${PACOTES[@]}"; do
        su ${MY_USER} -c "yay -S ${i} --needed --noconfirm"
    done 
}

function clonar_dotfiles(){
    su ${MY_USER} -c "cd /home/${MY_USER} && rm -rf .[^.] .??*" &> /dev/null
    su ${MY_USER} -c "cd /home/${MY_USER} && git clone --bare https://github.com/andreluizs/dotfiles.git /home/${MY_USER}/.dotfiles" 
    su ${MY_USER} -c "cd /home/${MY_USER} && /usr/bin/git --git-dir=/home/${MY_USER}/.dotfiles/ --work-tree=/home/${MY_USER} checkout"
}

#instalar_aur_helper
#clonar_dotfiles
#configurar_teclado
instalar_pacote
