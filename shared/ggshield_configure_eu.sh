#!/bin/bash
# ggshield EU Instance Configuration Script
#
# Points the ggshield CLI at GitGuardian's EU-hosted dashboard
# (https://dashboard.eu1.gitguardian.com) for the currently logged-in user.
#
# ggshield stores this setting in the invoking user's home directory
# (~/.gitguardian.yaml), not system-wide, so this script must run the
# config command as the console user rather than as root.

# _TEST_PATH_OVERRIDE is read only by the test suite; production runs always
# get the hardcoded value below.
export PATH="${_TEST_PATH_OVERRIDE:-/usr/bin:/bin:/usr/sbin:/sbin}"

# --- Configuration ---
INSTANCE_URL="https://dashboard.eu1.gitguardian.com"
GGSHIELD_PATH="${GGSHIELD_PATH:-/usr/local/bin/ggshield}"

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

if [[ ! -x "$GGSHIELD_PATH" ]]; then
	log "ERROR" "ggshield is not installed at $GGSHIELD_PATH."
	exit 1
fi

# --- Find the logged-in console user (config is per-user, not system-wide) ---
consoleUser=$(stat -f "%Su" /dev/console)
if [[ -z "$consoleUser" || "$consoleUser" == "root" || "$consoleUser" == "_mbsetupuser" ]]; then
	log "ERROR" "No logged-in user found; cannot configure ggshield instance."
	exit 1
fi

# --- Set the instance ---
log "INFO" "Setting ggshield instance to $INSTANCE_URL for user $consoleUser..."
setOut=$(sudo -u "$consoleUser" "$GGSHIELD_PATH" config set instance "$INSTANCE_URL" 2>&1)
setStatus=$?

if [[ $setStatus -ne 0 ]]; then
	log "ERROR" "Failed to set ggshield instance: $setOut"
	exit 1
fi

log "INFO" "ggshield instance set to $INSTANCE_URL for user $consoleUser."
exit 0
