#!/usr/bin/env bash
# Identidade da Akari: nome do sistema, ícones, padrões de tema e serviços.
set -oue pipefail
source /ctx/lib.sh

log "os-release"
# ID continua "fedora" para não quebrar ferramentas; o nome e o logo são da Akari.
OSR=/usr/lib/os-release
VERSION_ID="$(. "${OSR}" && echo "${VERSION_ID}")"
sed -i \
    -e 's/^NAME=.*/NAME="Akari"/' \
    -e "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Akari ${VERSION_ID} (base Fedora)\"/" \
    -e 's/^LOGO=.*/LOGO=akari-logo/' \
    -e 's/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME="akari"/' \
    -e 's|^HOME_URL=.*|HOME_URL="https://github.com/"|' \
    "${OSR}"
grep -q '^LOGO=' "${OSR}" || echo 'LOGO=akari-logo' >>"${OSR}"
grep -q '^DEFAULT_HOSTNAME=' "${OSR}" || echo 'DEFAULT_HOSTNAME="akari"' >>"${OSR}"
grep -q '^VARIANT_ID=' "${OSR}" && sed -i 's/^VARIANT_ID=.*/VARIANT_ID=akari/' "${OSR}" || echo 'VARIANT_ID=akari' >>"${OSR}"
grep -q '^VARIANT=' "${OSR}" && sed -i 's/^VARIANT=.*/VARIANT="Akari"/' "${OSR}" || echo 'VARIANT="Akari"' >>"${OSR}"
echo "AKARI_BUILD_DATE=$(date -u +%Y-%m-%d)" >>"${OSR}"

log "Caches de ícones e fontes"
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
fc-cache -f

log "Padrões do GTK (escuro, ícones Papirus, cursor Bibata)"
dconf update 2>/dev/null || true

log "Serviços"
systemctl enable akari-flatpak-setup.service
# A sessão da Akari é a única que a tela de login deve oferecer
for s in hyprland.desktop hyprland-uwsm.desktop; do
    f="/usr/share/wayland-sessions/${s}"
    [[ -f "${f}" ]] && echo "NoDisplay=true" >>"${f}"
done

log "Conferindo os arquivos da Akari"
for f in /usr/bin/akari-session /usr/libexec/akari/akari-user-setup /usr/libexec/akari/hajime \
    /usr/share/sddm/themes/genkan/Main.qml /usr/lib/akari/ichiba/ichiba.py \
    /usr/share/plymouth/themes/akari/akari.script /usr/share/akari/hypr/akari.lua; do
    [[ -e "${f}" ]] || { echo "Faltando: ${f}"; exit 1; }
done
