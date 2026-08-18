#!/usr/bin/env bash

###############################################################################
# NOC Tools
# Development Checks
###############################################################################

for required_command in git bash shellcheck shfmt; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'Error: required command not found: %s\n' "$required_command" >&2
        exit 1
    fi
done

DEV_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! REPOSITORY_ROOT="$(git -C "$DEV_SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
    printf 'Error: unable to resolve the Git repository root.\n' >&2
    exit 1
fi

cd "$REPOSITORY_ROOT" || {
    printf 'Error: unable to access repository: %s\n' "$REPOSITORY_ROOT" >&2
    exit 1
}

mapfile -d '' -t tracked_shell_files < <(git ls-files -z -- '*.sh')

active_shell_files=()
legacy_shell_files=()
for shell_file in "${tracked_shell_files[@]}"; do
    if [[ "$shell_file" == legacy/* ]]; then
        legacy_shell_files+=("$shell_file")
    else
        active_shell_files+=("./$shell_file")
    fi
done

printf 'NOC Tools Development Check\n\n'
printf 'Repository: %s\n' "$REPOSITORY_ROOT"
printf 'Active shell files: %s\n' "${#active_shell_files[@]}"
printf 'Legacy shell files excluded: %s\n\n' "${#legacy_shell_files[@]}"

if ((${#active_shell_files[@]} == 0)); then
    printf 'Error: no active tracked shell files found.\n' >&2
    exit 1
fi

result=0

if shellcheck -x "${active_shell_files[@]}"; then
    printf '[PASS] ShellCheck\n'
else
    printf '[FAIL] ShellCheck\n'
    result=1
fi

if shfmt -d "${active_shell_files[@]}"; then
    printf '[PASS] shfmt\n'
else
    printf '[FAIL] shfmt\n'
    result=1
fi

bash_syntax_result=0
for shell_file in "${active_shell_files[@]}"; do
    if ! bash -n "$shell_file"; then
        bash_syntax_result=1
    fi
done

if ((bash_syntax_result == 0)); then
    printf '[PASS] Bash syntax\n'
else
    printf '[FAIL] Bash syntax\n'
    result=1
fi

git_whitespace_result=0
if ! git diff --check; then
    git_whitespace_result=1
fi
if ! git diff --cached --check; then
    git_whitespace_result=1
fi

if ((git_whitespace_result == 0)); then
    printf '[PASS] Git whitespace\n'
else
    printf '[FAIL] Git whitespace\n'
    result=1
fi

printf '\nGit status:\n'
git status --short --branch

if ((result == 0)); then
    printf '\nResult: PASS\n'
else
    printf '\nResult: FAIL\n'
fi

exit "$result"
