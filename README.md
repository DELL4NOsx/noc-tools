# NOC Tools

NOC Tools is a small Bash command-line application for network diagnostics. The current MVP provides bounded ping and DNS A-record checks with captured command evidence and explicit result semantics.

## Status

- Version: `0.1.0-dev`
- State: early-development MVP; not production-ready
- Platform: Linux/Bash-first
- Scope: intentionally limited to a small CLI and two diagnostics

## Current Features

- CLI help, including `--help` and `-h` aliases
- Version output, including `--version` and `-v` aliases
- Project information through `about`
- Runtime dependency checks through `doctor`
- Ping diagnostics for a single target
- DNS A-record diagnostics for a single domain
- A development quality gate for maintained shell code
- An 18-test deterministic CLI smoke suite

## Requirements

Runtime requirements:

- Bash
- `ping`
- `dig`, commonly provided by DNS utility packages

The `doctor` command checks these three runtime dependencies without performing network operations.

Development checks additionally require:

- Git
- ShellCheck
- shfmt

No dependency installer is included.

## Usage

Run the CLI from the repository root:

```bash
./noc.sh
./noc.sh help
./noc.sh version
./noc.sh about
./noc.sh doctor
./noc.sh run ping <target>
./noc.sh run dns <domain>
```

Replace angle-bracket placeholders with actual values. The CLI is path-safe and can be invoked from another working directory by using the correct path to the repository script:

```bash
/path/to/noc-tools/noc.sh version
/path/to/noc-tools/noc.sh run dns example.com
```

NOC Tools is not installed into `PATH`, and the repository does not provide a global `noc` command.

## Diagnostics

### Ping

```bash
./noc.sh run ping <target>
```

The command accepts exactly one hostname, IPv4 address, or IPv6 address. Values beginning with `-` are rejected to prevent them from being interpreted as `ping` options.

The diagnostic:

- Uses the system `ping` command.
- Sends exactly three ICMP requests.
- Uses a bounded two-second per-reply wait for the Linux-first MVP.
- Runs the command with `LC_ALL=C`.
- Preserves the complete command output under `Evidence`.
- Reports `PASS` when `ping` succeeds.
- Reports `FAIL` when `ping` completes without a successful ICMP response.
- Reports `ERROR` for other operational or tool failures.

A missing ICMP response does not prove that a host is offline. ICMP can be filtered or disabled independently of other services.

### DNS

```bash
./noc.sh run dns <domain>
```

The command accepts exactly one domain-like argument. It rejects values beginning with `-`, `+`, or `@` so callers cannot inject `dig` options or resolver selection.

The diagnostic:

- Uses the system `dig` command and the system-configured resolver.
- Queries record type `A` only.
- Uses a two-second timeout and one attempt.
- Runs the command with `LC_ALL=C`.
- Preserves complete combined command output under `Evidence`.
- Parses the DNS protocol status and `ANSWER` count from the `dig` header.

Current classification:

| DNS outcome | Result |
| --- | --- |
| `NOERROR` and `ANSWER > 0` | `PASS` |
| `NOERROR` and `ANSWER = 0` | `FAIL` |
| `NXDOMAIN` | `FAIL` |
| Another parsed DNS failure status, such as `SERVFAIL` or `REFUSED` | `FAIL` |
| Command execution or parsing failure | `ERROR` |

The current MVP uses the `ANSWER` count to classify a positive A query. It does not inspect individual answer records as an advanced DNS parser would.

Custom resolvers, record-type selection, DNSSEC, EDE, and resolver comparison are not implemented.

## Result Semantics

`PASS`

The diagnostic completed and produced a positive result.

`FAIL`

The diagnostic completed correctly but produced a negative network result.

`ERROR`

The diagnostic could not be completed reliably because of a runtime, dependency, command, or parsing problem.

`FAIL` and `ERROR` are intentionally different: a negative observation is not the same as an inability to run or interpret the diagnostic.

## Exit Codes

| Code | Meaning |
| --- | --- |
| `0` | Successful command or positive diagnostic result |
| `1` | Runtime, internal, dependency, or diagnostic execution failure |
| `2` | CLI usage error, unknown command, or unknown diagnostic |
| `3` | Completed diagnostic with a negative result |

## Examples

Check runtime dependencies without sending network traffic:

```bash
./noc.sh doctor
```

Run a loopback ping diagnostic:

```bash
./noc.sh run ping 127.0.0.1
```

Run an A-record query through the system-configured resolver:

```bash
./noc.sh run dns example.com
```

Diagnostic commands print captured system-command output under `Evidence`, followed by the parsed result and interpretation. Exact evidence varies by system and network.

## Development Checks

Run the maintained-code quality gate:

```bash
./scripts/dev/check.sh
```

The script:

- Resolves the repository root from its own location.
- Discovers tracked `*.sh` files through Git.
- Excludes tracked files under `legacy/` from the active quality gate.
- Runs `shellcheck -x` against active shell files.
- Runs `shfmt -d` in check-only mode.
- Runs `bash -n` against every active shell file.
- Runs `git diff --check` and `git diff --cached --check`.
- Displays `git status --short --branch` for operator visibility.

A dirty working tree is displayed but does not fail the gate by itself.

## Smoke Tests

Run the deterministic smoke suite:

```bash
./tests/smoke.sh
```

The current suite contains 18 tests covering the base CLI, doctor, ping, DNS, and the public exit-code contract. It creates temporary fake `ping` and `dig` executables, prepends them to a test-specific `PATH`, and performs no real diagnostic network traffic.

Temporary files are removed through an exit trap. The suite resolves the repository root from its own location, so it can also run from an external working directory:

```bash
cd /tmp
/path/to/noc-tools/tests/smoke.sh
```

This is a focused smoke suite, not a complete test suite.

## Repository Structure

```text
noc-tools/
├── noc.sh
├── core/
├── modules/
│   ├── ping/
│   └── dns/
├── scripts/dev/
├── tests/
├── legacy/
├── docs/
├── VERSION
└── README.md
```

- `noc.sh`: CLI entry point, command validation, lazy module loading, and dispatch.
- `core/`: bootstrap path handling, the project banner, and version-file access.
- `modules/`: active diagnostic implementations. Modules perform no network work when merely sourced.
- `scripts/dev/`: maintained-code quality checks.
- `tests/`: deterministic CLI smoke testing.
- `legacy/`: sanitized historical/reference scripts. They are not part of the supported MVP or primary quality gate.
- `docs/`: currently contains only a minimal documentation index.
- `VERSION`: current project version consumed by the CLI.

## Current Limitations

- Bash/Linux-first; other platforms are not currently supported or verified.
- Only ping and DNS A-record diagnostics are implemented.
- DNS uses the system-configured resolver and does not support custom resolver selection.
- DNS does not support selectable record types, DNSSEC, or EDE analysis.
- No configuration system is exposed in the MVP.
- No persistent reports or diagnostic history.
- No TUI, web interface, or API.
- No automatic remediation.
- No plugin or provider system in the current MVP.

## License

NOC Tools is distributed under the GNU General Public License version 3. See [`LICENSE`](LICENSE) for the complete terms.
