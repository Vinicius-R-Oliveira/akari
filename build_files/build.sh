#!/usr/bin/env bash
# Orquestra o build da Akari: roda cada etapa em ordem.
set -oue pipefail

export FEDORA_VERSION="${FEDORA_VERSION:-44}"
export QUICKSHELL_PKG="${QUICKSHELL_PKG:-quickshell-git}"
export CAELESTIA_FROM_SOURCE="${CAELESTIA_FROM_SOURCE:-0}"
export CTX=/ctx

for step in "${CTX}"/steps/[0-9][0-9]-*.sh; do
    echo "::group::Akari ─ $(basename "${step}")"
    bash "${step}"
    echo "::endgroup::"
done
