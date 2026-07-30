# Contributing

## Setup

This repo uses [mise](https://mise.jdx.dev) to manage its toolchain (`shellcheck`, `shfmt`, `bats`,
`hk`, `pkl`, `dprint`).

```sh
mise install
```

This also wires up a git pre-commit hook (via [hk](https://hk.jdx.dev)) that runs `shellcheck` and
`shfmt` on staged shell scripts.

## Running checks manually

```sh
hk check --all   # shellcheck + shfmt, all files
hk fix --all     # same, but auto-fix what it can
bats test/       # run the test suite
dprint fmt       # format markdown files
```

CI (`.github/workflows/ci.yml`) runs `hk check --all` and `bats test/` on every push and pull
request.

## Tests

Tests live in `test/*.bats` and stub out external commands (`curl`, `spctl`, `installer`,
`codesign`, `uname`) via `test/stubs/`, so they don't touch the network or `/usr/local/bin`. Test
coverage is scoped to the security-critical branches — Team ID verification, Gatekeeper checks,
version comparison — rather than every possible code path.

When adding a script or changing install/audit logic, add or update the matching `.bats` file for
the branches that matter (what happens on a signature mismatch, an outdated version, a network
failure, etc.).

## Commit messages

This repo follows [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
`<type>: <description>`, imperative mood, no capital letter, no trailing period. Common types used
here: `feat`, `fix`, `test`, `build`, `style`, `ci`, `docs`.

## Repo structure

See the [README](README.md#structure) for how the MDM platform directories relate to
`shared/ggshield_install.sh`.
