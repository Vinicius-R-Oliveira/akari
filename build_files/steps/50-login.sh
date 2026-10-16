#!/usr/bin/env bash
# Genkan (tela de login no SDDM) e animação de boot (Plymouth).
set -oue pipefail
source /ctx/lib.sh

log "SDDM com Weston como compositor da tela de login"
need sddm sddm-wayland-generic weston qt6-qtdeclarative qt6-qtsvg
want qt6-qt5compat

systemctl enable sddm.service
systemctl set-default graphical.target

log "Plymouth com o tema Akari"
need plymouth plymouth-plugin-script plymouth-scripts
plymouth-set-default-theme akari
