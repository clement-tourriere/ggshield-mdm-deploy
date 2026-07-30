# ggshield MDM Deploy

MDM scripts to deploy and keep [ggshield](https://github.com/GitGuardian/ggshield) up to date on macOS.

Inspired by [Installomator](https://github.com/Installomator/Installomator).

## Supported MDM Platforms

| Platform          | Directory | Description                                           |
| ----------------- | --------- | ----------------------------------------------------- |
| [Kandji](kandji/) | `kandji/` | Audit & remediation scripts for Kandji Custom Scripts |
| [Jamf Pro](jamf/) | `jamf/`   | Install script and Extension Attribute for Jamf Pro   |

## Structure

```
shared/
  ggshield_install.sh        # Shared install script (single source of truth)
kandji/
  ggshield_audit.sh          # Kandji audit script
  ggshield_remediation.sh    # -> ../shared/ggshield_install.sh (symlink)
jamf/
  ggshield_install.sh        # -> ../shared/ggshield_install.sh (symlink)
  jamf_ea_ggshield_version.sh
```

The install logic lives in `shared/ggshield_install.sh`. Platform directories symlink to it. When uploading to your MDM, copy the resolved file contents.

## How It Works

The install script:

1. Fetches the latest ggshield release from GitHub (supports both Apple Silicon and Intel)
2. Verifies the `.pkg` signature via Gatekeeper (`spctl`) and validates the GitGuardian Team ID (`N67C7J5WQ9`)
3. Confirms the package is notarized by Apple
4. Installs the package and verifies the installed binary signature
