#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../shared/ggshield_install.sh"
STUBS="$BATS_TEST_DIRNAME/stubs"

setup() {
	FIXTURE_DIR="$(mktemp -d)"
	GGSHIELD_PATH="$FIXTURE_DIR/ggshield"
	_TEST_PATH_OVERRIDE="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin"
	export GGSHIELD_PATH _TEST_PATH_OVERRIDE
}

teardown() {
	rm -rf "$FIXTURE_DIR"
}

@test "fails when the latest version cannot be determined" {
	STUB_CURL_LATEST_FAIL=1 run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Could not determine latest ggshield version"* ]]
}

@test "fails when the download fails" {
	STUB_DOWNLOAD_FAIL=1 run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Download failed"* ]]
}

@test "fails Gatekeeper verification" {
	STUB_SPCTL_EXIT=1 run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"failed Gatekeeper verification"* ]]
}

@test "aborts on package Team ID mismatch" {
	STUB_SPCTL_TEAMID="EVILTEAMID" run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Team ID mismatch"* ]]
	[ ! -e "$GGSHIELD_PATH" ]
}

@test "fails when the installer fails" {
	STUB_INSTALLER_EXIT=1 run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Installation failed"* ]]
}

@test "aborts on installed binary Team ID mismatch" {
	STUB_CODESIGN_TEAMID="EVILTEAMID" run "$SCRIPT"
	[ "$status" -eq 1 ]
	[[ "$output" == *"Installed binary Team ID mismatch"* ]]
}

@test "installs and verifies successfully on the happy path" {
	STUB_LATEST_VERSION="1.35.0" STUB_INSTALLED_VERSION="1.35.0" run "$SCRIPT"
	[ "$status" -eq 0 ]
	[[ "$output" == *"1.35.0 installed and verified successfully"* ]]
	[ -x "$GGSHIELD_PATH" ]
}
