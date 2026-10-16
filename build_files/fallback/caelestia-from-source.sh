#!/usr/bin/env bash
# Plano B: compila o Caelestia Shell (+ CLI) direto do código-fonte,
# usado se o pacote do COPR não puder ser instalado.
set -oue pipefail
source /ctx/lib.sh

log "Compilando o Caelestia a partir do código-fonte"

BUILD_DEPS=(
    cmake ninja-build gcc-c++ git pkgconf-pkg-config
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel
    libqalculate-devel pipewire-devel aubio-devel fftw-devel lm_sensors-devel
    libcava-devel python3-pip
)

dnf5 -y install "${QUICKSHELL_PKG}" || need quickshell
need "${BUILD_DEPS[@]}"

latest_tag() {
    # Descobre a última release pelo redirecionamento do GitHub (sem API)
    curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/##'
}

SHELL_TAG="${CAELESTIA_SHELL_REF:-$(latest_tag caelestia-dots/shell)}"
CLI_TAG="${CAELESTIA_CLI_REF:-$(latest_tag caelestia-dots/cli)}"
log "Caelestia shell ${SHELL_TAG} / cli ${CLI_TAG}"

# M3Shapes (formas do Material 3 usadas pelo shell)
KEEP_BUILD_DEPS=1 bash /ctx/fallback/m3shapes-from-source.sh

SRC=/tmp/caelestia-shell
git clone --depth 1 --branch "${SHELL_TAG}" https://github.com/caelestia-dots/shell.git "${SRC}"
cmake -S "${SRC}" -B "${SRC}/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DDISTRIBUTOR=Akari \
    -DVERSION="${SHELL_TAG#v}" \
    -DGIT_REVISION="$(git -C "${SRC}" rev-parse HEAD)" \
    -DINSTALL_QSCONFDIR=/etc/xdg/quickshell/caelestia
cmake --build "${SRC}/build"
cmake --install "${SRC}/build"

# CLI em Python
want python3-pillow
pip install --root-user-action=ignore --prefix=/usr \
    "git+https://github.com/caelestia-dots/cli.git@${CLI_TAG}"

# Fontes que o pacote do COPR traria
want material-symbols-fonts rubik-fonts

# Remove só as ferramentas de compilação (as bibliotecas de runtime ficam)
dnf5 -y remove cmake ninja-build gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel \
    libqalculate-devel pipewire-devel aubio-devel fftw-devel lm_sensors-devel libcava-devel || true
rm -rf "${SRC}"
