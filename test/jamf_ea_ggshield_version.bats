#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../jamf/jamf_ea_ggshield_version.sh"

setup() {
	FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
	rm -rf "$FIXTURE_DIR"
}

write_fixture_binary() {
	cat >"$FIXTURE_DIR/ggshield" <<EOF
#!/bin/bash
echo "$1"
EOF
	chmod +x "$FIXTURE_DIR/ggshield"
}

@test "reports Not installed when the binary is missing" {
	GGSHIELD_PATH="$FIXTURE_DIR/ggshield" run "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "$output" = "<result>Not installed</result>" ]
}

@test "reports the parsed version when installed" {
	write_fixture_binary "ggshield, version 1.35.0"
	GGSHIELD_PATH="$FIXTURE_DIR/ggshield" run "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "$output" = "<result>1.35.0</result>" ]
}

@test "reports an error when the version cannot be parsed" {
	write_fixture_binary "not a version string"
	GGSHIELD_PATH="$FIXTURE_DIR/ggshield" run "$SCRIPT"
	[ "$status" -eq 0 ]
	[ "$output" = "<result>Error: unable to get version</result>" ]
}
