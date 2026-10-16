#!/usr/bin/env bash
# Compila o módulo QML M3Shapes, caso nenhum pacote o tenha instalado.
set -oue pipefail
source /ctx/lib.sh

if find /usr/lib64/qt6/qml -maxdepth 1 -type d -name 'M3Shapes' | grep -q .; then
    log "M3Shapes já presente"
    exit 0
fi

log "Compilando M3Shapes"
need cmake ninja-build gcc-c++ git qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel

# Mesmo commit fixado pelo Caelestia (flake.lock do caelestia-dots/shell)
M3_REF="${M3SHAPES_REF:-32ad9ce328bb77ed349b40a3be10ee9ea610b8ab}"
SRC=/tmp/m3shapes
git clone https://github.com/soramanew/m3shapes.git "${SRC}"
git -C "${SRC}" checkout "${M3_REF}" || log "Commit ${M3_REF} não encontrado, usando o mais recente"

cmake -S "${SRC}" -B "${SRC}/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DINSTALL_QMLDIR=lib64/qt6/qml
cmake --build "${SRC}/build"
cmake --install "${SRC}/build"
rm -rf "${SRC}"

# Quando chamado sozinho, remove as ferramentas de compilação
if [[ "${KEEP_BUILD_DEPS:-0}" != "1" ]]; then
    dnf5 -y remove cmake ninja-build gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtshadertools-devel || true
fi
