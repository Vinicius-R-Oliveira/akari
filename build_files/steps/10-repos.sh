#!/usr/bin/env bash
# Repositórios extras: Hyprland, Quickshell, Caelestia, VS Code e Steam.
set -oue pipefail
source /ctx/lib.sh

rpm -q dnf5-plugins >/dev/null || need dnf5-plugins

log "Habilitando COPRs"
# Hyprland 0.56+ (config em Lua, exigida pelo Caelestia atual)
dnf5 -y copr enable nett00n/hyprland
# Quickshell (a versão git acompanha o Caelestia)
dnf5 -y copr enable errornointernet/quickshell
# Caelestia Shell + CLI + fontes (Material Symbols, Rubik)
dnf5 -y copr enable celestelove/caelestia

# O COPR do Hyprland também tem um "quickshell"; deixamos o Quickshell
# vir só do COPR dedicado, para não haver duas versões brigando.
dnf5 config-manager setopt \
    "copr:copr.fedorainfracloud.org:nett00n:hyprland.excludepkgs=quickshell,quickshell-debuginfo,quickshell-debugsource" ||
    log "Aviso: não consegui excluir o quickshell do COPR do Hyprland (seguindo mesmo assim)"

log "Repositório do Visual Studio Code"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat >/etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

log "Repositório da Steam (negativo17, combina com o fedora-multimedia da base)"
if ! dnf5 repolist --all | grep -q fedora-steam; then
    dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo
fi
dnf5 config-manager setopt fedora-steam.enabled=1 || true

dnf5 makecache
