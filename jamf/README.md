# ggshield - Jamf Pro

Jamf Pro scripts to deploy and keep [ggshield](https://github.com/GitGuardian/ggshield) up to date on macOS.

Inspired by [Installomator](https://github.com/Installomator/Installomator).

## Scripts

### `ggshield_install.sh`

Symlink to [`../shared/ggshield_install.sh`](../shared/ggshield_install.sh). Policy script that:

1. Fetches the latest release from GitHub (supports both Apple Silicon and Intel)
2. Verifies the `.pkg` signature via Gatekeeper (`spctl`) and validates the Team ID
3. Confirms the package is notarized by Apple
4. Installs the package and verifies the installed binary signature

### `jamf_ea_ggshield_version.sh`

Jamf Pro Extension Attribute (Script, Data Type: String) that reports the installed ggshield version.

- Installed: outputs the version number (e.g. `2.5.0`)
- Not found: outputs `Not installed`
- Error: outputs `Error: unable to get version`

### `ggshield_configure_eu.sh`

Symlink to [`../shared/ggshield_configure_eu.sh`](../shared/ggshield_configure_eu.sh). Policy
script that points ggshield at GitGuardian's EU-hosted dashboard
(`https://dashboard.eu1.gitguardian.com`) for the logged-in console user. No editing required.

### `ggshield_configure_self_hosted.sh`

Symlink to
[`../shared/ggshield_configure_self_hosted.sh`](../shared/ggshield_configure_self_hosted.sh).
Policy script that points ggshield at a self-hosted GitGuardian instance for the logged-in console
user. Edit the `INSTANCE_URL` variable at the top of the script before uploading.

## Jamf Pro Setup

### Install Script

1. Upload `ggshield_install.sh` to **Settings > Scripts**
2. Create a **Policy** that runs the script
3. Scope to the appropriate computers/groups
4. Set the trigger (e.g. recurring check-in, or a Smart Group that targets machines without ggshield / with an outdated version)

### Extension Attribute

1. Go to **Settings > Extension Attributes > New**
2. Set **Data Type** to `String` and **Input Type** to `Script`
3. Paste the contents of `jamf_ea_ggshield_version.sh`
4. Use in Smart Groups to scope policies (e.g. target machines where ggshield version is not the latest)

### Instance Configuration (EU / self-hosted only)

1. Upload `ggshield_configure_eu.sh` or `ggshield_configure_self_hosted.sh` (edited with your URL)
   to **Settings > Scripts**
2. Create a **Policy** that runs the script, scoped after the install policy
3. Scope to the appropriate computers/groups
