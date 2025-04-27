# Lordmoritz Fortify Script

> **Secure. Harden. Fortify.**  
> Automated security for your Ubuntu servers by Chinonso Okoye (Gentmorris / Lordmoritz / Gentzycode).

---

## 🚀 About

**Lordmoritz Fortify** is a powerful, fully automated shell script designed to **harden**, **scan**, and **secure** Ubuntu-based servers with minimal effort.

It installs and configures industry-grade tools like **ClamAV**, **Fail2Ban**, **RKHunter**, **AIDE**, **UFW**, and **unattended-upgrades**.  
It intelligently schedules heavy tasks to run during off-peak hours, while immediately applying lightweight hardening tweaks.

**Fortify your VM like a true professional.**  
**No human intervention needed. Logs everything. Leaves no blind spots.**

---

## 📦 Features

- ✅ Firewall setup (UFW)
- ✅ Antivirus scanning (ClamAV)
- ✅ Rootkit scanning (RKHunter)
- ✅ File integrity monitoring (AIDE)
- ✅ Brute-force protection (Fail2Ban)
- ✅ SSH hardening (disable root login, password auth)
- ✅ Unattended security patching
- ✅ Smart cron scheduling (resource-friendly)
- ✅ Centralized security reports in `/var/log/security-reports`
- ✅ Fully idempotent (safe to run multiple times)

---

## 🛠️ Requirements

- OS: Ubuntu 20.04 / 22.04 / 24.04 (tested)
- User: Must be run as **root** (or via `sudo`)
- Internet access (for package installation)

---

## 📥 How to Install and Use

1. **Clone or download the script**
   ```bash
   git clone https://github.com/gentzycode/lordmoritz-fortify.git
   cd lordmoritz-fortify

2. **Make it executable**
   ```bash
   chmod +x lordmoritz-fortify.sh

3. **Run the Fortify Command**
    ```bash
    sudo ./lordmoritz-fortify.sh lordmoritz fortify me

✅ The script will only proceed if the command contains "lordmoritz fortify me" to prevent accidental misuse.

⚙️ Optional Customizations

Before running, you can open the script and adjust:
Variable | Purpose | Default
SKIP_HEAVY_SCANS | Skip resource-heavy scans (for very small servers) | false
SSH_HARDENING | Disable root SSH login, disable password auth | true
AUTO_UPDATES | Enable automatic security updates | true

Example to skip heavy scans:

    sudo SKIP_HEAVY_SCANS=true ./lordmoritz-fortify.sh lordmoritz fortify me

📄 What Happens After Running?

Immediate Actions:
UFW firewall enabled (allow SSH only)
Fail2Ban configured and started
SSH hardened (no root login, no password auth)
Unattended security patches activated
Scheduled (Daily/Weekly) Actions:
Daily ClamAV scan at midnight
Daily RKHunter check at 1:00 AM
Fail2Ban auto-maintenance at 2:00 AM
Weekly full AIDE integrity check on Sundays at 3:00 AM

📊 Logs and Reports
All important actions and security reports are saved in:
/var/log/security-reports/

Example files:
fortify_20250427_010000.log → Script main log
clamav-nightly-20250428.log → Virus scan results
rkhunter-nightly-20250428.log → Rootkit check results
aide-weekly-20250428.log → File integrity check

You can review reports using:
less /var/log/security-reports/fortify_*.log
🚨 Warnings to Watch Out For

If disk space is too low, AIDE initialization may fail.
If SSH restarts, active root SSH sessions might drop (ensure you have other access methods like cloud console).
If cron is disabled on your system, scheduled scans won't run (ensure cron service is active).

🧠 Why Lordmoritz Fortify?
Designed by an active cybersecurity strategist (Chinonso Okoye a.k.a Gentzycode).
Balances security and performance: intelligent heavy scan scheduling.
No-bloat: installs only what's necessary.
Designed for real production VMs, not just test environments.

🤝 Contributing
Suggestions or improvements are welcome!
Please submit an issue or pull request on GitHub.

🛡 License
This project is released under the MIT License.

"Secure everything you build. Fortify everything you own."

---
```markdown
Lordmoritz Fortify

