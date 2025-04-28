#!/bin/bash
# ======================================================
# Lordmoritz Fortify Script - Ultimate Auto-Hardening v2.0.0
# Author: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# Purpose: Fully automate Ubuntu VM hardening, monitoring, and self-healing
# License: MIT
# ======================================================

set -e  # Immediate exit on any error for safety

# --- Configuration ---
LOGDIR="/var/log/security-reports"
CUSTOM_AIDE_CONF="/etc/aide/aide.conf.d/99_lordmoritz_paths"
FORTIFY_DATE=$(date +%Y%m%d_%H%M%S)
FORTIFY_LOG="$LOGDIR/fortify_$FORTIFY_DATE.log"
COMMAND="${*,,}"
SKIP_HEAVY_SCANS="false"
SSH_HARDENING="true"
AUTO_UPDATES="true"

# --- Helper Functions ---
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$FORTIFY_LOG"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
log_warn() { echo -e "\e[33m[WARNING]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
die() { log_error "FATAL: $1"; exit 1; }
check_root() { [[ $(id -u) -eq 0 ]] || die "This script must be run as root."; }
verify_command() {
    [[ "$COMMAND" == *"lordmoritz fortify me"* ]] || {
        echo -e "\nUsage: \e[1m lordmoritz fortify me \e[0m"
        echo "Optional flags:"
        echo "  --skip-heavy-scans    (skip resource-heavy nightly tasks)"
        exit 1
    }
}
add_cron_job() {
    local job="$1"
    (crontab -l 2>/dev/null || true) | grep -F -q "$job" || {
        (crontab -l 2>/dev/null; echo "$job") | crontab -
    }
}
heal_fail2ban() {
    if grep -q "database disk image is malformed" /var/log/fail2ban.log 2>/dev/null; then
        log_warn "Fail2Ban database corrupted. Rebuilding..."
        rm -f /var/lib/fail2ban/fail2ban.sqlite3
        systemctl restart fail2ban || log_error "Failed to restart Fail2Ban"
    fi
}
heal_aide() {
    if [[ -f /var/lib/aide/aide.db.new ]]; then
        log_success "Finalizing AIDE database..."
        cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    fi
}
recommend_livepatch() {
    if ! canonical-livepatch status &>/dev/null; then
        log_warn "Canonical Livepatch not detected. Consider enabling for zero-downtime kernel patches."
    fi
}

# --- Main Execution ---
verify_command
check_root

mkdir -p "$LOGDIR"
chown root:adm "$LOGDIR"
chmod 750 "$LOGDIR"

log_success "=== [Lordmoritz Fortify Start] ==="

# Phase 1: Essentials
log "Installing security essentials..."
apt update >> "$FORTIFY_LOG" 2>&1
apt install -y clamav rkhunter aide fail2ban ufw unattended-upgrades >> "$FORTIFY_LOG" 2>&1

log "Configuring UFW firewall..."
ufw allow OpenSSH >> "$FORTIFY_LOG" 2>&1
ufw --force enable >> "$FORTIFY_LOG" 2>&1 || log_warn "UFW enable skipped"

# Phase 2: Nightly Scans
if [[ "$SKIP_HEAVY_SCANS" != "true" ]]; then
    log "Scheduling nightly security scans..."
    add_cron_job "0 0 * * * /usr/bin/clamscan -r --bell -i / > $LOGDIR/clamav-nightly-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "30 0 * * * /usr/bin/rkhunter --update --quiet >> $LOGDIR/rkhunter-update-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "0 1 * * * /usr/bin/rkhunter --check --skip-keypress --report-warnings-only > $LOGDIR/rkhunter-nightly-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "0 2 * * * /bin/systemctl restart fail2ban >> $LOGDIR/fail2ban-restart-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "0 3 * * 0 /usr/bin/aide --check > $LOGDIR/aide-weekly-\$(date +\%Y\%m\%d).log 2>&1"
fi

# Phase 3: AIDE Configuration
log "Configuring AIDE monitoring..."
mkdir -p /etc/aide/aide.conf.d/
cat <<EOF > "$CUSTOM_AIDE_CONF"
# Lordmoritz Custom AIDE Paths
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide
@@define NORMAL_READONLY p+i+n+u+g+s+b+m+c+sha256
@@define LOOSE_READONLY p+i+n+u+g

/boot NORMAL_READONLY
/bin NORMAL_READONLY
/sbin NORMAL_READONLY
/etc NORMAL_READONLY
/usr/bin NORMAL_READONLY
/usr/sbin NORMAL_READONLY
/var/www NORMAL_READONLY
/opt NORMAL_READONLY

!/proc
!/sys
!/dev
!/run
!/tmp
!/var/tmp
EOF

log "Initializing AIDE database..."
aideinit --yes >> "$FORTIFY_LOG" 2>&1 || log_warn "AIDE initialization had warnings."

# Phase 4: SSH Hardening
if [[ "$SSH_HARDENING" == "true" ]]; then
    log "Hardening SSH settings..."
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd >> "$FORTIFY_LOG" 2>&1 || log_warn "SSH restart failed"
fi

# Phase 5: Auto Security Updates
if [[ "$AUTO_UPDATES" == "true" ]]; then
    log "Configuring automatic security updates..."
    dpkg-reconfigure -f noninteractive unattended-upgrades >> "$FORTIFY_LOG" 2>&1
    echo 'Unattended-Upgrade::Automatic-Reboot "true";' > /etc/apt/apt.conf.d/50unattended-upgrades
fi

# Healing
heal_fail2ban
heal_aide
recommend_livepatch

# Final Summary
log_success "[Lordmoritz Fortification Completed]"
echo "Reports Directory: $LOGDIR"
echo "Review nightly scan logs and consider Livepatch service."
exit 0
