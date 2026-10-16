#!/usr/bin/env bash
# Fecha a imagem: desliga repositórios extras, limpa caches e refaz o initramfs
# (necessário para a animação de boot da Akari aparecer).
set -oue pipefail
source /ctx/lib.sh

log "Desligando repositórios extras na imagem final"
# As atualizações chegam como imagem nova (build diário no GitHub),
# então os repositórios não precisam ficar ativos no sistema instalado.
for repo in $(dnf5 repolist --enabled | awk '/^copr:/{print $1}'); do
    dnf5 config-manager setopt "${repo}.enabled=0"
done
sed -i 's/^enabled=1/enabled=0/' /etc/yum.repos.d/vscode.repo
dnf5 config-manager setopt fedora-steam.enabled=0 || true

dnf5 clean all

log "Initramfs (Plymouth)"
KERNEL_VERSION="$(rpm -q --queryformat='%{evr}.%{arch}' kernel-core | tail -n1)"
export DRACUT_NO_XATTR=1
/usr/bin/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree \
    -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 "/lib/modules/${KERNEL_VERSION}/initramfs.img"

# Relatório: avisa no GitHub (anotação) se algum pacote importante ficou de fora
for p in hyprland quickshell-git caelestia-shell mpvpaper mpv kitty dolphin firefox code steam sddm; do
    rpm -q "$p" >/dev/null 2>&1 && echo "::notice title=Pacote ok::$p" || echo "::warning title=Pacote faltando::$p"
done
