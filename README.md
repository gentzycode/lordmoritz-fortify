# Lordmoritz Fortify ⚡

![Lordmoritz Fortify](https://img.shields.io/badge/FORTIFY-v2.1.6-purple?style=for-the-badge)
![GitHub License](https://img.shields.io/badge/License-MIT-blue.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange)

---

> 🛡️ **The Ultimate Script for Automated Ubuntu VM Hardening, Healing, and Monitoring**
> Built for professionals who demand automated, no-human-intervention security.
> Designed by **Chinonso Okoye** (*Lordmoritz / Gentmorris / Gentzycode*)

---

## ✨ Features

| ✅ Feature                    | 💡 Description                                                      |
| ---------------------------- | ------------------------------------------------------------------- |
| **Security Tools**           | Installs ClamAV, RKHunter, AIDE, Fail2Ban, UFW, unattended-upgrades |
| **Firewall & SSH Hardening** | Disables root login, enables UFW, enforces strong SSH policies      |
| **Nightly Scans**            | Runs daily checks for malware, rootkits, file integrity             |
| **Self-Healing**             | Rebuilds corrupted Fail2Ban DB and finalizes AIDE DB automatically  |
| **Auto-Updates**             | Enables unattended upgrades with optional auto-reboot               |
| **Low Resource Impact**      | Use `--skip-heavy-scans` for lightweight operation                  |
| **Self-Updating**            | Supports `lordmoritz upgrade me` to fetch the latest version        |
| **Detailed Logs**            | Logs to `/var/log/security-reports/` with timestamped history       |
| **UFW Backup**               | Auto-backs up UFW config before rule changes (v2.1.2+)              |
| **Progress Spinner**         | Real-time visual feedback for long operations (v2.1.3+)             |
| **Database IP Restriction**  | Restrict MySQL/PostgreSQL access to specific IPs (v2.1.3+)          |
| **Dry Run Mode**             | Use `--dry-run` to simulate changes without execution (v2.1.3+)     |
| **ASCII Art Banner**         | Enhanced UX with styled startup banner (v2.1.3+)                    |
| **Version Awareness**        | Notifies if a newer version is available (v2.1.3+)                  |

---

## 🚀 Quick Start

### 1. 📥 Clone the Repository

```bash
git clone https://github.com/gentzycode/lordmoritz-fortify.git
cd lordmoritz-fortify
```

### 2. 🧱 Run the Installer

```bash
sudo bash INSTALL.sh
```

### 3. 🔐 Fortify the VM

```bash
sudo lordmoritz-fortify lordmoritz fortify me
```

### 4. ⚙️ Optional Usage Examples

```bash
# Skip heavy scans (lightweight environments)
sudo lordmoritz-fortify lordmoritz fortify me --skip-heavy-scans

# Disable SSH hardening\sudo lordmoritz-fortify lordmoritz fortify me --no-ssh-hardening

# Disable automatic security updates
sudo lordmoritz-fortify lordmoritz fortify me --no-auto-updates

# Run without prompts (unattended mode)
sudo lordmoritz-fortify lordmoritz fortify me --unattended

# Dry-run mode (simulate actions without applying changes)
sudo lordmoritz-fortify lordmoritz fortify me --dry-run
```

### 5. 🔁 Upgrade Script

```bash
sudo lordmoritz-fortify lordmoritz upgrade me
```

---

## 📁 Files and Structure

| File/Folder                  | Purpose                              |
| ---------------------------- | ------------------------------------ |
| `INSTALL.sh`                 | Initial installer and bootstrapper   |
| `lordmoritz-fortify.sh`      | Main fortification script            |
| `/var/log/security-reports/` | Logs and nightly/weekly scan reports |

---

## 🛡️ Security Activities Performed

| Module           | Action                                   |
| ---------------- | ---------------------------------------- |
| **ClamAV**       | Full filesystem malware scans            |
| **RKHunter**     | Rootkit detection and alerting           |
| **AIDE**         | Filesystem integrity monitoring          |
| **Fail2Ban**     | Blocks brute-force attacks               |
| **UFW**          | Configures firewall and OpenSSH access   |
| **Auto-Updates** | Enables daily automatic security patches |

---

## 🖥️ System Requirements

* Ubuntu **20.04**, **22.04**, or **24.04**
* Root privileges (`sudo`)

---

## 🧠 Recommendations After Fortification

🔹 Enable Canonical Livepatch: [Canonical Livepatch Setup](https://ubuntu.com/security/livepatch)
🔹 Set a Legal Warning Banner: Edit `/etc/motd`
🔹 Monitor Nightly Reports: Check `/var/log/security-reports/`
🔹 Review/Adjust AIDE Rules: Found under `/etc/aide/`

---

## 🛠️ Troubleshooting

| Issue                     | Suggestion                                           |
| ------------------------- | ---------------------------------------------------- |
| **Installation Fails**    | Check network and disk space (`df -h`)               |
| **Cron Jobs Not Running** | Confirm with `crontab -l`                            |
| **Missing Logs**          | Review `/var/log/security-reports/` for errors       |
| **Script Errors**         | Use `--dry-run` to debug before full execution       |
| **Git Issues**            | Ensure Git is installed and repo access is available |

---

## 📜 License

MIT License — Free to use, modify, and distribute.
© 2025 Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)

---

## 🙌 Contributing

Contributions are welcome! Follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/YourFeature`
3. Commit your changes: `git commit -m 'Add YourFeature'`
4. Push to GitHub: `git push origin feature/YourFeature`
5. Open a Pull Request on GitHub

---

🛡️ **Happy Hardening and Stay Secure!**
