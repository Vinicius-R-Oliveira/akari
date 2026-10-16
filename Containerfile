# ─────────────────────────────────────────────────────────────
#  Akari 灯り — imagem bootc baseada no Fedora atômico
# ─────────────────────────────────────────────────────────────
#  Versão do Fedora usada como base. Os repositórios COPR usados
#  (Hyprland, Quickshell, Caelestia) têm builds para 44 e 45.
ARG FEDORA_VERSION=44

# Contexto de build: scripts e arquivos de sistema ficam fora da
# imagem final, montados só durante o RUN.
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base: Universal Blue "base-main" = Fedora atômico sem desktop,
# já com codecs, mesa completo (AMD), Flathub e atualizações automáticas.
FROM ghcr.io/ublue-os/base-main:${FEDORA_VERSION}

ARG FEDORA_VERSION=44
# Pacote do Quickshell a preferir (o Caelestia acompanha a versão git).
ARG QUICKSHELL_PKG=quickshell-git
# Se "1", compila o Caelestia a partir do código em vez de usar o COPR.
ARG CAELESTIA_FROM_SOURCE=0

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    FEDORA_VERSION="${FEDORA_VERSION}" \
    QUICKSHELL_PKG="${QUICKSHELL_PKG}" \
    CAELESTIA_FROM_SOURCE="${CAELESTIA_FROM_SOURCE}" \
    /ctx/build.sh

# Verifica se a imagem final está correta para o bootc
RUN bootc container lint
