#!/usr/bin/env bash

###############################################################################
# NOC Tools
# Smoke Tests
###############################################################################

TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! REPOSITORY_ROOT="$(git -C "$TEST_SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    printf 'Error: unable to resolve the Git repository root.\n' >&2
    exit 1
fi

ORIGINAL_PATH="$PATH"
BASH_PATH="$(command -v bash)"
TEMP_ROOT="$(mktemp -d /tmp/noc-tools-smoke.XXXXXX)" || {
    printf 'Error: unable to create temporary test directory.\n' >&2
    exit 1
}

case "$TEMP_ROOT" in
/tmp/noc-tools-smoke.*) ;;
*)
    printf 'Error: unexpected temporary directory: %s\n' "$TEMP_ROOT" >&2
    exit 1
    ;;
esac

trap 'rm -rf -- "$TEMP_ROOT"' EXIT

FAKE_BIN="$TEMP_ROOT/bin"
DOCTOR_MISSING_BIN="$TEMP_ROOT/doctor-missing-bin"
STDOUT_FILE="$TEMP_ROOT/stdout"
STDERR_FILE="$TEMP_ROOT/stderr"
mkdir -p "$FAKE_BIN" "$DOCTOR_MISSING_BIN"

cat >"$FAKE_BIN/ping" <<'EOF'
#!/usr/bin/env bash

if [[ -n "${FAKE_PING_MARKER:-}" ]]; then
    printf 'executed\n' >"$FAKE_PING_MARKER"
fi

case "${FAKE_PING_MODE:-positive}" in
positive)
    printf 'PING example.test (192.0.2.1): 56 data bytes\n'
    printf '3 packets transmitted, 3 packets received, 0%% packet loss\n'
    exit 0
    ;;
negative)
    printf 'PING example.test (192.0.2.1): 56 data bytes\n'
    printf '3 packets transmitted, 0 packets received, 100%% packet loss\n'
    exit 1
    ;;
error)
    printf 'ping: simulated operational error\n' >&2
    exit 2
    ;;
*)
    printf 'fake ping: unknown mode\n' >&2
    exit 2
    ;;
esac
EOF

cat >"$FAKE_BIN/dig" <<'EOF'
#!/usr/bin/env bash

case "${FAKE_DIG_MODE:-positive}" in
positive)
    printf '%s\n' ';; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1'
    printf '%s\n' ';; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1'
    exit 0
    ;;
nxdomain)
    printf '%s\n' ';; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 1'
    printf '%s\n' ';; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1'
    exit 0
    ;;
noanswer)
    printf '%s\n' ';; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1'
    printf '%s\n' ';; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1'
    exit 0
    ;;
servfail)
    printf '%s\n' ';; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 1'
    printf '%s\n' ';; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 1'
    exit 0
    ;;
error)
    printf 'dig: simulated operational error\n' >&2
    exit 9
    ;;
unparseable)
    printf 'simulated unparseable dig output\n'
    exit 0
    ;;
*)
    printf 'fake dig: unknown mode\n' >&2
    exit 9
    ;;
esac
EOF

chmod 755 "$FAKE_BIN/ping" "$FAKE_BIN/dig"
ln -s "$BASH_PATH" "$DOCTOR_MISSING_BIN/bash"
ln -s "$(command -v dirname)" "$DOCTOR_MISSING_BIN/dirname"
ln -s "$FAKE_BIN/dig" "$DOCTOR_MISSING_BIN/dig"

CLI_STATUS=0
CLI_STDOUT=""
CLI_STDERR=""
tests=0
passed=0
failed=0

run_cli() {
    : >"$STDOUT_FILE"
    : >"$STDERR_FILE"
    PATH="$FAKE_BIN:$ORIGINAL_PATH" "$REPOSITORY_ROOT/noc.sh" "$@" >"$STDOUT_FILE" 2>"$STDERR_FILE"
    CLI_STATUS=$?
    CLI_STDOUT="$(cat "$STDOUT_FILE")"
    CLI_STDERR="$(cat "$STDERR_FILE")"
}

run_cli_with_missing_ping() {
    : >"$STDOUT_FILE"
    : >"$STDERR_FILE"
    PATH="$DOCTOR_MISSING_BIN" "$BASH_PATH" "$REPOSITORY_ROOT/noc.sh" doctor >"$STDOUT_FILE" 2>"$STDERR_FILE"
    CLI_STATUS=$?
    CLI_STDOUT="$(cat "$STDOUT_FILE")"
    CLI_STDERR="$(cat "$STDERR_FILE")"
}

pass_test() {
    tests=$((tests + 1))
    passed=$((passed + 1))
    printf '[PASS] %s\n' "$1"
}

fail_test() {
    tests=$((tests + 1))
    failed=$((failed + 1))
    printf '[FAIL] %s\n' "$1"
    printf '  Expected: %s\n' "$2"
    printf '  Actual exit: %s\n' "$CLI_STATUS"
    printf '  Actual stdout: %s\n' "${CLI_STDOUT:-<empty>}"
    printf '  Actual stderr: %s\n' "${CLI_STDERR:-<empty>}"
}

assert_output() {
    local name="$1"
    local expected_status="$2"
    local expected_text
    local matches=0
    shift 2

    if ((CLI_STATUS != expected_status)); then
        matches=1
    fi

    for expected_text in "$@"; do
        if [[ "$CLI_STDOUT" != *"$expected_text"* ]]; then
            matches=1
        fi
    done

    if ((matches == 0)); then
        pass_test "$name"
    else
        fail_test "$name" "exit $expected_status and stdout containing: $*"
    fi
}

printf 'NOC Tools Smoke Tests\n\n'

run_cli version
if ((CLI_STATUS == 0)) && [[ "$CLI_STDOUT" == "0.1.0-dev" && -z "$CLI_STDERR" ]]; then
    pass_test 'version'
else
    fail_test 'version' 'exit 0, exact stdout 0.1.0-dev, empty stderr'
fi

run_cli help
assert_output 'help' 0 'help' 'version' 'about' 'doctor' 'run ping <target>' 'run dns <domain>'

run_cli about
assert_output 'about' 0 'NOC Tools'

run_cli unknown
if ((CLI_STATUS == 2)) && [[ -z "$CLI_STDOUT" && -n "$CLI_STDERR" ]]; then
    pass_test 'unknown command'
else
    fail_test 'unknown command' 'exit 2, empty stdout, nonempty stderr'
fi

run_cli version unexpected
if ((CLI_STATUS == 2)) && [[ -n "$CLI_STDERR" ]]; then
    pass_test 'extra arguments'
else
    fail_test 'extra arguments' 'exit 2 and nonempty stderr'
fi

run_cli doctor
assert_output 'doctor available' 0 'bash    OK' 'ping    OK' 'dig     OK' 'Result: PASS'

run_cli_with_missing_ping
assert_output 'doctor missing dependency' 1 'ping    MISSING' 'Result: FAIL'

FAKE_PING_MODE=positive run_cli run ping example.test
assert_output 'ping positive' 0 'Evidence:' 'Result: PASS'

FAKE_PING_MODE=negative run_cli run ping example.test
assert_output 'ping no reply' 3 'Evidence:' 'Result: FAIL'

FAKE_PING_MODE=error run_cli run ping example.test
assert_output 'ping operational error' 1 'Evidence:' 'Result: ERROR'

PING_MARKER="$TEMP_ROOT/ping-executed"
FAKE_PING_MARKER="$PING_MARKER" run_cli run ping -c
if ((CLI_STATUS == 2)) && [[ ! -e "$PING_MARKER" ]]; then
    pass_test 'ping invalid input'
else
    fail_test 'ping invalid input' 'exit 2 without executing ping'
fi

FAKE_DIG_MODE=positive run_cli run dns example.com
assert_output 'dns positive' 0 'DNS status: NOERROR' 'Answers: 2' 'Result: PASS'

FAKE_DIG_MODE=nxdomain run_cli run dns nonexistent.example
assert_output 'dns NXDOMAIN' 3 'DNS status: NXDOMAIN' 'Answers: 0' 'Result: FAIL'

FAKE_DIG_MODE=noanswer run_cli run dns example.com
assert_output 'dns no answer' 3 'DNS status: NOERROR' 'Answers: 0' 'Result: FAIL'

FAKE_DIG_MODE=servfail run_cli run dns example.com
assert_output 'dns SERVFAIL' 3 'DNS status: SERVFAIL' 'Result: FAIL'

FAKE_DIG_MODE=error run_cli run dns example.com
assert_output 'dns operational error' 1 'Evidence:' 'Result: ERROR'

FAKE_DIG_MODE=unparseable run_cli run dns example.com
assert_output 'dns unparseable output' 1 'Evidence:' 'Result: ERROR'

run_cli run dns +short
if ((CLI_STATUS == 2)) && [[ -n "$CLI_STDERR" ]]; then
    pass_test 'dns invalid input'
else
    fail_test 'dns invalid input' 'exit 2 and nonempty stderr'
fi

printf '\nTests: %s\n' "$tests"
printf 'Passed: %s\n' "$passed"
printf 'Failed: %s\n' "$failed"

if ((failed == 0)); then
    printf '\nResult: PASS\n'
    exit 0
fi

printf '\nResult: FAIL\n'
exit 1
