#!/usr/bin/env bash

###############################################################################
# Project:
#   NOC Tools
#
# File:
#   noc.sh
#
# Description:
#   Entry point of the NOC Tools application.
#
# Author:
#   Dellanno Braga
#
# License:
#   GPLv3
###############################################################################

# =============================================================================
# Bootstrap
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=core/bootstrap.sh
if ! source "$SCRIPT_DIR/core/bootstrap.sh"; then
    echo "Erro: não foi possível inicializar o NOC Tools." >&2
    exit 1
fi

# =============================================================================
# Main
# =============================================================================

print_help() {
    print_banner
    printf 'Usage:\n'
    printf '  noc.sh <command>\n\n'
    printf 'Commands:\n'
    printf '  help\n'
    printf '  version\n'
    printf '  about\n'
    printf '  doctor\n'
    printf '  run ping <target>\n'
}

print_version() {
    local version

    if ! version="$(get_version)"; then
        printf 'Erro: não foi possível ler o arquivo VERSION.\n' >&2
        return 1
    fi

    printf '%s\n' "$version"
}

print_about() {
    local version

    if ! version="$(get_version)"; then
        printf 'Erro: não foi possível ler o arquivo VERSION.\n' >&2
        return 1
    fi

    print_banner
    printf 'NOC Tools\n'
    printf 'Plataforma Open Source para diagnóstico de redes.\n'
    printf 'Version : %s\n' "$version"
    printf 'Status  : Em desenvolvimento\n'
    printf 'Licença : GPLv3\n'
}

print_doctor() {
    local dependency
    local result=0

    printf 'NOC Tools Doctor\n\n'

    for dependency in bash ping dig; do
        if command -v "$dependency" >/dev/null 2>&1; then
            printf '%-8sOK\n' "$dependency"
        else
            printf '%-8sMISSING\n' "$dependency"
            result=1
        fi
    done

    if ((result == 0)); then
        printf '\nResult: PASS\n'
    else
        printf '\nResult: FAIL\n'
    fi

    return "$result"
}

print_usage_error() {
    printf 'Erro: %s\n' "$1" >&2
    printf 'Use "noc.sh help" para ver os comandos disponíveis.\n' >&2
}

command="${1:-help}"

case "$command" in
help | --help | -h)
    if (($# > 1)); then
        print_usage_error "argumentos extras não são permitidos para '$1'."
        exit 2
    fi
    print_help
    ;;
version | --version | -v)
    if (($# > 1)); then
        print_usage_error "argumentos extras não são permitidos para '$1'."
        exit 2
    fi
    print_version || exit 1
    ;;
about)
    if (($# > 1)); then
        print_usage_error "argumentos extras não são permitidos para '$1'."
        exit 2
    fi
    print_about || exit 1
    ;;
doctor)
    if (($# > 1)); then
        print_usage_error "argumentos extras não são permitidos para '$1'."
        exit 2
    fi
    print_doctor || exit 1
    ;;
run)
    if (($# < 2)); then
        print_usage_error 'uso: noc.sh run ping <target>.'
        exit 2
    fi

    if [[ "$2" != "ping" ]]; then
        print_usage_error "diagnóstico desconhecido: '$2'."
        exit 2
    fi

    if (($# != 3)) || [[ -z "$3" || "$3" == -* ]]; then
        print_usage_error 'uso: noc.sh run ping <target>.'
        exit 2
    fi

    # shellcheck source=modules/ping/module.sh
    if ! source "$PROJECT_ROOT/modules/ping/module.sh"; then
        printf 'Erro: não foi possível carregar o módulo de ping.\n' >&2
        exit 1
    fi

    if ! declare -F run_ping_diagnostic >/dev/null; then
        printf 'Erro: módulo de ping inválido.\n' >&2
        exit 1
    fi

    run_ping_diagnostic "$3"
    exit $?
    ;;
*)
    print_usage_error "comando desconhecido: '$command'."
    exit 2
    ;;
esac
