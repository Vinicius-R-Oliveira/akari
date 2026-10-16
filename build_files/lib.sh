#!/usr/bin/env bash
# Funções de apoio usadas pelas etapas do build.

# Instala pacotes que a Akari precisa obrigatoriamente (falha o build se faltar).
need() {
    dnf5 -y install --setopt=install_weak_deps=False "$@"
}

# Instala pacotes "bons de ter": o que não existir no repositório é ignorado.
want() {
    dnf5 -y install --setopt=install_weak_deps=False --skip-unavailable "$@"
}

# Baixa um arquivo com algumas tentativas.
fetch() {
    local url="$1" out="$2"
    curl --fail --location --retry 4 --retry-delay 3 --silent --show-error -o "${out}" "${url}"
}

# Verifica se uma família de fonte já está instalada.
has_font() {
    fc-list : family | grep -qi -- "$1"
}

log() {
    echo -e "\033[1;37m[akari]\033[0m $*"
}
