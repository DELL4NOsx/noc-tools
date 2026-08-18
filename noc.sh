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
    echo "Error: NOC Tools initialization failed." >&2
    exit 1
fi

# =============================================================================
# Main
# =============================================================================

print_help() {
    print_banner
    printf 'Usage:\n'
    printf '  noc.sh <command> [arguments]\n\n'
    printf 'Commands:\n'
    printf '  help                 Show this help\n'
    printf '  version              Show NOC Tools version\n'
    printf '  about                Show project information\n'
    printf '  doctor               Check runtime dependencies\n'
    printf '  run ping <target>    Run an ICMP diagnostic\n'
    printf '  run dns <domain>     Run a DNS A-record diagnostic\n'
}

print_version() {
    local version

    if ! version="$(get_version)"; then
        printf 'Error: unable to read the VERSION file.\n' >&2
        return 1
    fi

    printf '%s\n' "$version"
}

print_about() {
    local version

    if ! version="$(get_version)"; then
        printf 'Error: unable to read the VERSION file.\n' >&2
        return 1
    fi

    print_banner
    printf 'NOC Tools\n'
    printf 'Open Source Network Diagnostics CLI.\n'
    printf 'Version : %s\n' "$version"
    printf 'Status  : Early development\n'
    printf 'License : GPLv3\n'
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
    printf 'Error: %s\n' "$1" >&2
    printf 'Use "noc.sh help" to see available commands.\n' >&2
}

command="${1:-help}"

case "$command" in
help | --help | -h)
    if (($# > 1)); then
        print_usage_error "extra arguments are not allowed for '$1'."
        exit 2
    fi
    print_help
    ;;
version | --version | -v)
    if (($# > 1)); then
        print_usage_error "extra arguments are not allowed for '$1'."
        exit 2
    fi
    print_version || exit 1
    ;;
about)
    if (($# > 1)); then
        print_usage_error "extra arguments are not allowed for '$1'."
        exit 2
    fi
    print_about || exit 1
    ;;
doctor)
    if (($# > 1)); then
        print_usage_error "extra arguments are not allowed for '$1'."
        exit 2
    fi
    print_doctor || exit 1
    ;;
run)
    if (($# < 2)); then
        print_usage_error 'usage: noc.sh run <diagnostic> <argument>.'
        exit 2
    fi

    if [[ "$2" == "ping" ]]; then
        if (($# != 3)) || [[ -z "$3" || "$3" == -* ]]; then
            print_usage_error 'usage: noc.sh run ping <target>.'
            exit 2
        fi

        # shellcheck source=modules/ping/module.sh
        if ! source "$PROJECT_ROOT/modules/ping/module.sh"; then
            printf 'Error: unable to load the ping module.\n' >&2
            exit 1
        fi

        if ! declare -F run_ping_diagnostic >/dev/null; then
            printf 'Error: invalid ping module.\n' >&2
            exit 1
        fi

        run_ping_diagnostic "$3"
        exit $?
    fi

    if [[ "$2" == "dns" ]]; then
        if (($# != 3)) || [[ -z "$3" || "$3" == [-+@]* ]]; then
            print_usage_error 'usage: noc.sh run dns <domain>.'
            exit 2
        fi

        # shellcheck source=modules/dns/module.sh
        if ! source "$PROJECT_ROOT/modules/dns/module.sh"; then
            printf 'Error: unable to load the DNS module.\n' >&2
            exit 1
        fi

        if ! declare -F run_dns_diagnostic >/dev/null; then
            printf 'Error: invalid DNS module.\n' >&2
            exit 1
        fi

        run_dns_diagnostic "$3"
        exit $?
    fi

    if [[ "$2" != "ping" && "$2" != "dns" ]]; then
        print_usage_error "unknown diagnostic: '$2'."
        exit 2
    fi
    ;;
*)
    print_usage_error "unknown command: '$command'."
    exit 2
    ;;
esac
