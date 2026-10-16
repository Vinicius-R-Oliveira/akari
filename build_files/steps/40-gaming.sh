#!/usr/bin/env bash
# Jogos: Steam (com Proton), GameMode, MangoHud e Gamescope.
# A Epic Games entra pelo Heroic (Flatpak), instalado no primeiro boot.
set -oue pipefail
source /ctx/lib.sh

log "Steam"
need steam
log "Ferramentas de jogo"
want gamemode mangohud gamescope vulkan-tools steam-devices
