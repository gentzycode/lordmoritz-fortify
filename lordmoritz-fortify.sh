#!/bin/bash
# ======================================================
# Lordmoritz Fortify Script - Ultimate Cron-Optimized Edition (v2)
# By: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# Purpose: Harden, heal, monitor, and auto-fortify Ubuntu VMs
# ======================================================

# --- Configuration ---
LOGDIR="/var/log/security-reports"
SKIP_HEAVY_SCANS="false"
MAX_RUNTIME_HOURS=6
SSH_HARDENING="true"
AUTO_UPDATES="true"
COMMAND="${*,,}"
DATE=$(date +%Y%m%d_%H%M%S)
FORTIFY_LOG="$LOGDIR/fortify_$DATE.log"
AIDE_CONF="/etc/aide/aide.conf"

# --- Initialization ---
mkdir -p "$LOGDIR"
chown root:adm "$LOGDIR"
chmod 750 "$LOGDIR"

# --- Helper Functions ---
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$FORTIFY_LOG"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
log_warn() { echo -e "\e[33m[WARNING]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1" | tee -a "$FORTIFY_LOG"; }
die() { log_error "FATAL: $1"; exit 1; }
check_root() { [[ $(id -u) -eq 0 ]] || die "This script must run as root"; }

verify_command() {
    [[ "$COMMAND" == *"lordmoritz fortify me"* ]] || {
        echo "Usage: lordmoritz fortify me"
        echo "Optional flags: --skip-heavy-scans"
        exit 1
    }
}

retry() {
    local n=0
    until [ "$n" -ge 3 ]; do
        "$@" && break
        n=$((n+1))
        log_warn "Retrying ($n) $*..."
        sleep 2
    done
    [ "$n" -lt 3 ] || die "Command failed after 3 retries: $*"
}

add_cron_job() {
    local job="$1"
    if ! crontab -l 2>/dev/null | grep -Fq "$job"; then
        (crontab -l 2>/dev/null; echo "$job") | crontab - || die "Failed to add cron job"
    fi
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

# --- Main Execution ---
verify_command
check_root

log_success "=== Starting Fortification (Lordmoritz Ultimate) ==="

# Phase 1: Lightweight Immediate Tasks
log "Installing security essentials..."
retry apt update
retry apt install -y clamav rkhunter aide fail2ban ufw unattended-upgrades

log "Setting up UFW firewall..."
retry ufw allow OpenSSH
retry ufw --force enable

# Phase 2: Scheduled Heavy Tasks
if [[ "$SKIP_HEAVY_SCANS" != "true" ]]; then
    log "Scheduling nightly scans..."
    add_cron_job "0 0 * * * /usr/bin/clamscan -r --bell -i / > $LOGDIR/clamav-nightly-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "30 0 * * * /usr/bin/rkhunter --update --quiet >> $LOGDIR/rkhunter-update-\$(date +\%Y\%m\%d).log 2>&1"
    add_cron_job "0 1 * * * /usr/bin/rkhunter --check --skip-keypress --report-warnings-only > $LOGDIR/rkhunter-nightly-\$(date +\%Y\%m\%d).log 2>&1"

    log "Configuring AIDE monitoring paths..."
    cat <<EOF > "$AIDE_CONF"
@@define DBDIR /var/lib/aide
@@define LOGDIR /var/log/aide
@@define NORMAL_READONLY p+i+n+u+g+s+b+m+c+sha256
@@define LOOSE_READONLY p+i+n+u+g
EOF

    for dir in /boot /bin /sbin /etc /usr/bin /usr/sbin /var/www /opt; do
        [[ -d "$dir" ]] && echo "$dir NORMAL_READONLY" >> "$AIDE_CONF"
    done
    echo -e "\n# Exclusions\n!/proc\n!/sys\n!/dev\n!/run\n!/tmp\n!/var/tmp" >> "$AIDE_CONF"

    if [[ ! -f /var/lib/aide/aide.db ]]; then
        log "Initializing AIDE..."
        aideinit --yes || log_warn "AIDE init failed. Disk space?"
    fi
fi

# Phase 3: Hardening
log "Applying system hardening..."

if [[ "$SSH_HARDENING" == "true" ]]; then
    log "Hardening SSH settings..."
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd || log_warn "SSH restart failed"
fi

if [[ "$AUTO_UPDATES" == "true" ]]; then
    log "Configuring automatic updates..."
    retry dpkg-reconfigure -f noninteractive unattended-upgrades
    echo 'Unattended-Upgrade::Automatic-Reboot "true";' > /etc/apt/apt.conf.d/50unattended-upgrades
fi

# Phase 4: Extra Scheduled Maintenances
log "Setting up maintenance cron jobs..."
add_cron_job "0 2 * * * /bin/systemctl restart fail2ban >> $LOGDIR/fail2ban-restart-\$(date +\%Y\%m\%d).log 2>&1"
add_cron_job "0 3 * * 0 /usr/bin/aide --check > $LOGDIR/aide-weekly-\$(date +\%Y\%m\%d).log 2>&1"

# Healing Common Issues
heal_fail2ban
heal_aide

# Post Execution Summary
log_success "Fortification Complete!"
log "Reports available under $LOGDIR:"
ls -lh "$LOGDIR" | tee -a "$FORTIFY_LOG"

log "Recommendations:"
log "- Consider enabling Canonical Livepatch for kernel auto-patching."
log "- Set a legal warning banner in /etc/motd."
exit 0
