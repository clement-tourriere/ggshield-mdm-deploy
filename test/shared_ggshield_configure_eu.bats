#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../shared/ggshield_configure_eu.sh"
STUBS="$BATS_TEST_DIRNAME/stubs"
EU_URL="https://dashboard.eu1.gitguardian.com"

setup() {
	FIXTURE_DIR="$(mktemp -d)"
	GGSHIELD_PATH="$FIXTURE_DIR/ggshield"
	_TEST_PATH_OVERRIDE="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin"
	export GGSHIELD_PATH _TEST_PATH_OVERRIDE
}

teardown() {
	rm -rf "$FIXTURE_DIR"
}

write_fixture_ggshield() {
	cat >"$GGSHIELD_PATH" <<'EOF'
#!/bin/bash
if [[ "$1" == "config" && "$2" == "set" && "$3" == "instance" ]]; then
	if [[ -n "$STUB_CONFIG_SET_EXIT" && "$STUB_CONFIG_SET_EXIT" != "0" ]]; then
		echo "config set failed" >&2
		exit "$STUB_CONFIG_SET_EXIT"
	fi
	echo "instance set to $4"
	exit 0
fi
exit 1
EOF
	chmod +x "$GGSHIELD_PATH"
}

@test "fails when ggshield is not installed" {
	run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"ggshield is not installed"* ]]
}

@test "fails when no user is logged in" {
	write_fixture_ggshield
	STUB_CONSOLE_USER="" run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"No logged-in user found"* ]]
}

@test "fails when the console user is root" {
	write_fixture_ggshield
	STUB_CONSOLE_USER="root" run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"No logged-in user found"* ]]
}

@test "fails when setting the instance fails" {
	write_fixture_ggshield
	STUB_CONFIG_SET_EXIT=1 run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Failed to set ggshield instance"* ]]
}

@test "sets the EU instance for the console user" {
	write_fixture_ggshield
	STUB_CONSOLE_USER="jane" run "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"instance set to $EU_URL"* ]]
	[[ "$output" == *"ggshield instance set to $EU_URL for user jane"* ]]
}
