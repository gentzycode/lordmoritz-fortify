# Lordmoritz Fortify ⚡

![Lordmoritz Fortify](https://img.shields.io/badge/FORTIFY-v2.1.4-purple?style=for-the-badge)
![GitHub License](https://img.shields.io/badge/License-MIT-blue.svg)
![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20%7C%2022.04%20%7C%2024.04-orange)

---

**The Ultimate Script for Automated Ubuntu VM Hardening, Healing, and Monitoring**  
Built for professionals who demand automated, no-human-intervention security.  
Designed by **Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)**.

---

✨ Features

✅ Automated Security Tool Installation: ClamAV, RKHunter, AIDE, Fail2Ban, UFW, and unattended-upgrades.
✅ Firewall and SSH Hardening: Configures UFW and secures SSH with no root login and key-based authentication.
✅ Nightly Security Scans: Scheduled scans for malware, rootkits, and filesystem integrity.
✅ Self-Healing: Automatically fixes Fail2Ban database corruption and finalizes AIDE databases.
✅ Automatic Updates: Enables unattended security patches with optional auto-reboot.
✅ Low Resource Usage: Optimized for minimal system impact with --skip-heavy-scans option.
✅ Self-Upgrading: Updates itself via lordmoritz upgrade me command.
✅ Detailed Logging: Comprehensive reports in /var/log/security-reports/.
✅ UFW Rules Backup: Automatically backs up UFW rules before modification (introduced in v2.1.2).


🚀 Quick Start

Clone the Repository:
git clone https://github.com/gentzycode/lordmoritz-fortify.git
cd lordmoritz-fortify


Run the Installer:
sudo bash INSTALL.sh


Fortify the VM:
lordmoritz fortify me


(Optional) Skip Heavy Scans:
sudo lordmoritz-fortify lordmoritz fortify me --skip-heavy-scans
sudo lordmoritz-fortify lordmoritz fortify me --no-ssh-hardening
sudo lordmoritz-fortify lordmoritz fortify me --no-auto-updates


(Optional) Upgrade Script:
sudo lordmoritz-fortify lordmoritz upgrade me




📂 Files and Structure



File
Purpose



INSTALL.sh
Installer and bootstrapper


lordmoritz-fortify.sh
Main fortification script


/var/log/security-reports/
All security scan logs and operation reports



🛡️ Security Activities Performed



Module
Action



ClamAV
Full filesystem malware scans


RKHunter
Rootkit detection and alerts


AIDE
Filesystem integrity monitoring


Fail2Ban
Protection against brute-force attacks


UFW
Firewall activation and OpenSSH allowance


Auto-Updates
Automatic security patches



🖥️ System Requirements

Ubuntu 20.04, 22.04 or newer
Root privileges


🧠 Recommendations After Fortification

🔹 Enable Canonical Livepatch: Canonical Livepatch Setup
🔹 Set a Legal Warning Banner:Edit /etc/motd
🔹 Monitor Nightly Reports:View /var/log/security-reports/
🔹 Review/Adjust AIDE Rules if needed under /etc/aide/


🛠️ Troubleshooting

🔹 Installation Issues: Verify internet connectivity and sufficient disk space (df -h).
🔹 Cron Jobs: Check scheduled tasks with crontab -l.
🔹 Logs: Review detailed logs in /var/log/security-reports/.
🔹 Report Bugs: Submit issues at GitHub Issues.


📜 License
MIT License — Free to use, modify, and distribute.
© 2025 Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)

🙌 Contributing
Contributions are welcome! Please:

Fork the repository.
Create a feature branch (git checkout -b feature/YourFeature).
Commit your changes (git commit -m 'Add YourFeature').
Push to the branch (git push origin feature/YourFeature).
Open a Pull Request.


