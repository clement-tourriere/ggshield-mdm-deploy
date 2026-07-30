#!/bin/zsh --no-rcs
# ggshield Install Script
#
# Downloads and installs the latest ggshield from GitHub releases.
# Uses the native .pkg installer for macOS.
# Supports both Apple Silicon (arm64) and Intel (x86_64).
#
# Security: Verifies package signature via spctl (Gatekeeper) and
# validates the Team ID matches GitGuardian before installation.
# Inspired by Installomator (https://github.com/Installomator/Installomator)

# _TEST_PATH_OVERRIDE is read only by the test suite; production runs always
# get the hardcoded value below.
export PATH="${_TEST_PATH_OVERRIDE:-/usr/bin:/bin:/usr/sbin:/sbin}"

# --- Configuration ---
GIT_USER="GitGuardian"
GIT_REPO="ggshield"
EXPECTED_TEAM_ID="N67C7J5WQ9" # GitGuardian Inc.
GGSHIELD_PATH="${GGSHIELD_PATH:-/usr/local/bin/ggshield}"
TEMP_DIR=$(mktemp -d)

# --- Functions ---
cleanup() {
	rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

# --- Determine architecture ---
arch=$(uname -m)
if [[ "$arch" == "arm64" ]]; then
	archPattern="arm64-apple-darwin.pkg"
else
	archPattern="x86_64-apple-darwin.pkg"
fi

# --- Get latest version ---
latestVersion=$(curl -sLI "https://github.com/$GIT_USER/$GIT_REPO/releases/latest" |
	grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9.]//g')

if [[ -z "$latestVersion" ]]; then
	log "ERROR" "Could not determine latest ggshield version."
	exit 1
fi
log "INFO" "Latest version: $latestVersion"

# --- Get download URL ---
# Try GitHub API first, fall back to constructed URL
downloadURL=$(curl -sf "https://api.github.com/repos/$GIT_USER/$GIT_REPO/releases/latest" |
	awk -F '"' "/browser_download_url/ && /$archPattern\"/ { print \$4; exit }")

if [[ -z "$downloadURL" ]]; then
	# Fallback: construct URL directly (ggshield uses predictable naming)
	downloadURL="https://github.com/$GIT_USER/$GIT_REPO/releases/download/v${latestVersion}/ggshield-${latestVersion}-${archPattern}"
	log "WARN" "API fallback, using constructed URL: $downloadURL"
fi

log "INFO" "Download URL: $downloadURL"

# --- Download ---
pkgFile="$TEMP_DIR/ggshield-${latestVersion}.pkg"

log "INFO" "Downloading ggshield $latestVersion..."
curl -sfL "$downloadURL" -o "$pkgFile"

if [[ ! -f "$pkgFile" || ! -s "$pkgFile" ]]; then
	log "ERROR" "Download failed."
	exit 1
fi

# --- Verify package signature with spctl (Gatekeeper) ---
log "INFO" "Verifying package signature..."
spctlOut=$(spctl -a -vv -t install "$pkgFile" 2>&1)
spctlStatus=$?

if [[ $spctlStatus -ne 0 ]]; then
	log "ERROR" "Package failed Gatekeeper verification: $spctlOut"
	exit 1
fi
log "INFO" "Gatekeeper: $spctlOut"

# --- Verify Team ID matches expected (à la Installomator expectedTeamID) ---
teamID=$(echo "$spctlOut" | awk -F '(' '/origin=/ {print $2}' | tr -d '()')
if [[ -z "$teamID" ]]; then
	teamID=$(echo "$spctlOut" | awk -F '=' '/origin=/ {print $NF}')
fi

log "INFO" "Team ID: $teamID (expected: $EXPECTED_TEAM_ID)"

if [[ "$teamID" != "$EXPECTED_TEAM_ID" ]]; then
	log "ERROR" "Team ID mismatch! Got '$teamID', expected '$EXPECTED_TEAM_ID'. Aborting."
	exit 1
fi

# --- Verify package is notarized ---
if echo "$spctlOut" | grep -qi "notarized"; then
	log "INFO" "Package is notarized by Apple."
else
	log "WARN" "Package notarization status could not be confirmed."
fi

# --- Install ---
log "INFO" "Installing ggshield $latestVersion..."
installerOut=$(installer -pkg "$pkgFile" -target / 2>&1)
installerStatus=$?

if [[ $installerStatus -ne 0 ]]; then
	log "ERROR" "Installation failed: $installerOut"
	exit 1
fi
log "INFO" "$installerOut"

# --- Verify installation and binary signature ---
if [[ ! -x "$GGSHIELD_PATH" ]]; then
	log "ERROR" "ggshield binary not found after installation."
	exit 1
fi

installedVersion=$("$GGSHIELD_PATH" --version 2>/dev/null | sed 's/[^0-9.]//g')

# Verify the installed binary is also signed by the expected team
binaryTeamID=$(codesign -dv "$GGSHIELD_PATH" 2>&1 | awk -F= '/TeamIdentifier/ {print $2}')
if [[ "$binaryTeamID" != "$EXPECTED_TEAM_ID" ]]; then
	log "ERROR" "Installed binary Team ID mismatch! Got '$binaryTeamID', expected '$EXPECTED_TEAM_ID'."
	exit 1
fi

log "INFO" "ggshield $installedVersion installed and verified successfully (Team ID: $binaryTeamID)."
exit 0
