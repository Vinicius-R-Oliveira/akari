#!/usr/bin/env bash
# Desktop: Hyprland + Caelestia Shell e tudo que o shell usa por baixo.
set -oue pipefail
source /ctx/lib.sh

log "Hyprland"
need hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpicker hyprpolkitagent

log "Caelestia Shell + CLI"
if [[ "${CAELESTIA_FROM_SOURCE}" != "1" ]]; then
    # Primeiro tenta com o Quickshell preferido; se o resolvedor recusar,
    # deixa o próprio dnf escolher o Quickshell que o pacote pede.
    if ! dnf5 -y install "${QUICKSHELL_PKG}" caelestia-shell caelestia-cli; then
        log "Combinação com ${QUICKSHELL_PKG} falhou; tentando sem fixar o Quickshell"
        if ! dnf5 -y install caelestia-shell caelestia-cli; then
            log "Pacote do COPR indisponível: indo para o plano B (código-fonte)"
            CAELESTIA_FROM_SOURCE=1
        fi
    fi
fi
if [[ "${CAELESTIA_FROM_SOURCE}" == "1" ]]; then
    bash /ctx/fallback/caelestia-from-source.sh
fi
# Garante o módulo QML de formas (vem junto no pacote; se não vier, compila)
bash /ctx/fallback/m3shapes-from-source.sh

rpm -q --whatprovides quickshell quickshell-git 2>/dev/null || true

log "Dependências de runtime do Caelestia"
want \
    ddcutil brightnessctl lm_sensors aubio libqalculate libcava cava \
    NetworkManager NetworkManager-wifi bluez bluez-tools \
    pipewire wireplumber pipewire-pulseaudio pipewire-alsa pipewire-jack-audio-connection-kit \
    qt6-qtimageformats qt6-qtsvg qt6-qtmultimedia qt6-qtwayland \
    swappy grim slurp wl-clipboard cliphist fuzzel trash-cli \
    gammastep geoclue2 gnome-keyring playerctl ydotool \
    xdg-user-dirs xdg-utils jq libnotify mpv mpvpaper \
    material-symbols-fonts rubik-fonts cascadia-code-nerd-fonts

log "Firmware e drivers para notebook (Wi-Fi, GPU AMD, áudio, Bluetooth)"
# A base já traz a maioria; aqui só garante (o que já existe é ignorado)
want linux-firmware amd-gpu-firmware amd-ucode-firmware \
    iwlwifi-mvm-firmware realtek-firmware mt7xxx-firmware atheros-firmware brcmfmac-firmware \
    alsa-sof-firmware mesa-vulkan-drivers mesa-dri-drivers fwupd

# Perfis de energia (o Fedora usa o tuned-ppd, que fala a mesma API)
if ! rpm -q tuned-ppd >/dev/null && ! rpm -q power-profiles-daemon >/dev/null; then
    want tuned-ppd || want power-profiles-daemon
fi
systemctl enable tuned.service 2>/dev/null || true
systemctl enable bluetooth.service 2>/dev/null || true

log "Dotfiles do Caelestia (configs do Hyprland, fish, fastfetch, btop...)"
DOTS=/usr/share/akari/caelestia-dots
rm -rf "${DOTS}" && mkdir -p "${DOTS}"
fetch "https://codeload.github.com/caelestia-dots/caelestia/tar.gz/refs/heads/${CAELESTIA_DOTS_REF:-main}" /tmp/dots.tgz
tar -xzf /tmp/dots.tgz -C "${DOTS}" --strip-components=1
rm -f /tmp/dots.tgz
# Guarda de onde veio, para o setup do usuário saber quando atualizar
date -u +%Y%m%d >"${DOTS}/.akari-version"
