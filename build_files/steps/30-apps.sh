#!/usr/bin/env bash
# Apps da Akari: terminal, arquivos, navegador, editor e o que os configs usam.
set -oue pipefail
source /ctx/lib.sh

log "Apps principais"
need kitty dolphin firefox code fish python3-pyside6 flatpak

log "Integração dos apps KDE (Dolphin) fora do Plasma"
want kio-extras kio-admin ffmpegthumbs kdegraphics-thumbnailers kde-cli-tools \
    plasma-integration plasma-breeze breeze-icon-theme qt6-qtsvg

log "Ferramentas de terminal usadas pelos configs do Caelestia"
want fastfetch btop starship eza zoxide direnv bat ripgrep fd-find git \
    micro cmatrix unzip p7zip p7zip-plugins mpv imv pwvucontrol pavucontrol

log "Temas GTK/ícones"
want adw-gtk3-theme papirus-icon-theme

FONTDIR=/usr/share/fonts/akari
mkdir -p "${FONTDIR}"

log "Fontes Nerd (terminal e ícones do prompt)"
for f in JetBrainsMono CascadiaCode; do
    if ! has_font "${f/CascadiaCode/CaskaydiaCove} Nerd"; then
        fetch "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${f}.tar.xz" "/tmp/${f}.tar.xz"
        mkdir -p "${FONTDIR}/${f}"
        tar -xJf "/tmp/${f}.tar.xz" -C "${FONTDIR}/${f}" --wildcards '*.ttf'
        rm -f "/tmp/${f}.tar.xz"
    fi
done

log "Material Symbols (ícones do shell)"
if ! has_font "Material Symbols Rounded"; then
    fetch "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL,GRAD,opsz,wght%5D.ttf" \
        "${FONTDIR}/MaterialSymbolsRounded.ttf"
fi

log "Cursor Bibata Modern Ice (branco, combina com o preto e branco)"
fetch "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz" /tmp/bibata.tar.xz
tar -xJf /tmp/bibata.tar.xz -C /usr/share/icons
rm -f /tmp/bibata.tar.xz

fc-cache -f
