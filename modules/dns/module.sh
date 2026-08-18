#!/usr/bin/env bash

###############################################################################
# NOC Tools
# DNS Diagnostic Module
###############################################################################

run_dns_diagnostic() {
    local domain="$1"
    local dig_output
    local dig_status
    local dns_status
    local answer_count

    if ! command -v dig >/dev/null 2>&1; then
        printf 'Error: required dependency not found: dig.\n' >&2
        return 1
    fi

    dig_output="$(LC_ALL=C dig +time=2 +tries=1 "$domain" A 2>&1)"
    dig_status=$?

    printf 'NOC Tools DNS Diagnostic\n\n'
    printf 'Domain: %s\n' "$domain"
    printf 'Record type: A\n\n'
    printf 'Evidence:\n%s\n' "$dig_output"

    if ((dig_status != 0)); then
        printf '\nResult: ERROR\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS diagnostic could not be completed reliably.\n'
        return 1
    fi

    if [[ "$dig_output" =~ status:[[:space:]]*([A-Z]+), ]]; then
        dns_status="${BASH_REMATCH[1]}"
    else
        printf '\nResult: ERROR\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS diagnostic could not be completed reliably.\n'
        return 1
    fi

    if [[ "$dig_output" =~ ANSWER:[[:space:]]*([0-9]+), ]]; then
        answer_count="${BASH_REMATCH[1]}"
    else
        printf '\nResult: ERROR\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS diagnostic could not be completed reliably.\n'
        return 1
    fi

    printf '\nDNS status: %s\n' "$dns_status"
    printf 'Answers: %s\n' "$answer_count"

    if [[ "$dns_status" == "NOERROR" ]] && ((answer_count > 0)); then
        printf '\nResult: PASS\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS query completed successfully and returned an A record.\n'
        return 0
    fi

    if [[ "$dns_status" == "NOERROR" ]]; then
        printf '\nResult: FAIL\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS query completed successfully, but no A record was returned.\n'
        printf 'The domain may exist without an A record.\n'
        return 3
    fi

    if [[ "$dns_status" == "NXDOMAIN" ]]; then
        printf '\nResult: FAIL\n\n'
        printf 'Interpretation:\n'
        printf 'The DNS resolver reports that the queried domain does not exist.\n'
        return 3
    fi

    printf '\nResult: FAIL\n\n'
    printf 'Interpretation:\n'
    printf 'The resolver returned a DNS failure status: %s.\n' "$dns_status"
    return 3
}
