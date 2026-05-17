# for arm64 arch

---
## Ultra Lockdown System (root-del.sh)

An experimental, irreversible system lockdown and automated LUKS encryption module designed for Arch Linux (ARM64). 

**⚠️ WARNING: EXTREME DANGER ⚠️**
This script permanently locks down the system. It is intended strictly as an automated backend module for early OS testing. **Do not run this on a production machine.**

### Features

* **Absolute Root Lockout:** Generates a 256-character random root password, applies it, and permanently locks the root account (`passwd -l`).
* **Strict Kernel Hardening:** Modifies `sysctl` to disable kernel module loading, SysRq, unprivileged BPF, and restricts `dmesg` and kernel pointers.
* **Automated LUKS Keygen:** Generates a 512-character random key file for LUKS.
* **Seamless Boot Unlock:** Automatically detects the underlying LUKS root device, applies the new keyfile, updates `/etc/crypttab`, and patches `mkinitcpio.conf` to allow the system to boot automatically without user input.
* **Trace Removal:** Clears sensitive variables and wipes the bash history upon completion.

### Prerequisites

* Arch Linux (ARM64)
* Root privileges (`sudo`)
* The root filesystem (`/`) must already reside on a LUKS-encrypted volume (`/dev/mapper/...`)

### Usage

Execute the script with root privileges:

```bash
sudo ./tiwutos-uls.sh
```
---
