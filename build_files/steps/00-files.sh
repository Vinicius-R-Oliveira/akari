#!/usr/bin/env bash
# Copia os arquivos de sistema da Akari para a imagem.
set -oue pipefail
source /ctx/lib.sh

log "Copiando system_files para /"
cp -avf /ctx/system_files/. /

# O zip/git nem sempre preserva o bit de execução: garante aqui.
chmod 0755 /usr/bin/akari-* /usr/bin/ichiba /usr/libexec/akari/* 2>/dev/null || true
chmod 0755 /usr/lib/akari/ichiba/ichiba.py 2>/dev/null || true
