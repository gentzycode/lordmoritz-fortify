
# Lordmoritz Fortify ⚡

![Lordmoritz Fortify](https://img.shields.io/badge/FORTIFY-v1.0.0-purple?style=for-the-badge)

---

**The Ultimate Script for Automated Ubuntu VM Hardening, Healing, and Monitoring**  
Built for professionals who demand automated, no-human-intervention security.  
Designed by **Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)**.

---

## ✨ Features
- ✅ Automated installation and setup of security tools
- ✅ Harden firewall (`ufw`) and SSH (`/etc/ssh/sshd_config`)
- ✅ Deploy unattended security patches (`unattended-upgrades`)
- ✅ Set up nightly virus, rootkit, and integrity scans via cron jobs
- ✅ Heal common system issues (Fail2Ban db recovery, AIDE db initialization)
- ✅ Minimal system footprint and optimized for low-resource VMs

---

## 🚀 Quick Start

1. **Clone the Repository:**
    ```bash
    git clone https://github.com/gentzycode/lordmoritz-fortify.git
    cd lordmoritz-fortify
    ```

2. **Run the Installer:**
    ```bash
    sudo bash INSTALL.sh
    ```

3. **Fortify the VM:**
    ```bash
    lordmoritz fortify me
    ```

4. *(Optional)* **Skip Heavy Scans:**
    ```bash
    lordmoritz fortify me --skip-heavy-scans
    ```

---

## 📂 Files and Structure

| File | Purpose |
|:-----|:--------|
| `INSTALL.sh` | Installer and bootstrapper |
| `fortify.sh` | Main fortification script |
| `/var/log/security-reports/` | All security scan logs and operation reports |

---

## 🛡️ Security Activities Performed

| Module | Action |
|:-------|:-------|
| ClamAV | Full filesystem malware scans |
| RKHunter | Rootkit detection and alerts |
| AIDE | Filesystem integrity monitoring |
| Fail2Ban | Protection against brute-force attacks |
| UFW | Firewall activation and OpenSSH allowance |
| Auto-Updates | Automatic security patches |

---

## 🖥️ System Requirements
- Ubuntu 20.04, 22.04 or newer
- Root privileges

---

## 🧠 Recommendations After Fortification
- 🔹 **Enable Canonical Livepatch**: [Canonical Livepatch Setup](https://ubuntu.com/security/livepatch)
- 🔹 **Set a Legal Warning Banner**:
  Edit `/etc/motd`
- 🔹 **Monitor Nightly Reports**:
  View `/var/log/security-reports/`
- 🔹 **Review/Adjust AIDE Rules** if needed under `/etc/aide/`

---

## 📜 License

**MIT License** — Free to use, modify, and distribute.

© 2025 Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)

---
