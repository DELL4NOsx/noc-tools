#!/usr/bin/env bash

###############################################################################
# NOC Tools
# Ping Diagnostic Module
###############################################################################

run_ping_diagnostic() {
    local target="$1"
    local ping_output
    local ping_status

    if ! command -v ping >/dev/null 2>&1; then
        printf 'Error: required dependency not found: ping.\n' >&2
        return 1
    fi

    ping_output="$(LC_ALL=C ping -c 3 -W 2 "$target" 2>&1)"
    ping_status=$?

    printf 'NOC Tools Ping Diagnostic\n\n'
    printf 'Target: %s\n' "$target"
    printf 'Packets: 3\n\n'
    printf 'Evidence:\n%s\n' "$ping_output"

    if ((ping_status == 0)); then
        printf '\nResult: PASS\n\n'
        printf 'Interpretation:\n'
        printf 'The target responded to ICMP.\n'
        return 0
    fi

    if ((ping_status == 1)); then
        printf '\nResult: FAIL\n\n'
        printf 'Interpretation:\n'
        printf 'No successful ICMP response was received.\n'
        printf 'This does not necessarily mean the host is offline; ICMP may be filtered.\n'
        return 3
    fi

    printf '\nResult: ERROR\n\n'
    printf 'Interpretation:\n'
    printf 'The ping diagnostic could not be completed reliably.\n'
    return 1
}
