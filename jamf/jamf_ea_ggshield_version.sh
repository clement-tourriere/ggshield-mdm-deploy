#!/bin/zsh --no-rcs
# Jamf Pro Extension Attribute - ggshield Version
#
# Reports the installed ggshield version.
# Data Type: String
# Input Type: Script

GGSHIELD_PATH="/usr/local/bin/ggshield"

if [[ ! -x "$GGSHIELD_PATH" ]]; then
	echo "<result>Not installed</result>"
	exit 0
fi

version=$("$GGSHIELD_PATH" --version 2>/dev/null | sed 's/[^0-9.]//g')

if [[ -z "$version" ]]; then
	echo "<result>Error: unable to get version</result>"
	exit 0
fi

echo "<result>$version</result>"
exit 0
