#!/bin/bash
# ======================================================
# Lordmoritz Fortify Script - Ultimate Auto-Hardening v2.1.1
# Author: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# Purpose: Fully automate Ubuntu VM hardening, monitoring, healing, and self-upgrading
# License: MIT
# Last Updated: 2025-04-28
# ======================================================

set -e  # Immediate exit on any error
set -u  # Treat unset variables as errors

# --- Configuration ---
readonly LOGDIR="/var/log/security-reports"
readonly CUSTOM_AIDE_CONF="/etc/aide/aide.conf.d/99_lordmoritz_paths"
readonly INSTALL_DIR="/opt/lordmoritz-fortify"
readonly REPO_URL="https://github.com/gentzycode/lordmoritz-fortify.git"
readonly FORTIFY_DATE=$(date +%Y%m%d_%H%M%S)
readonly FORTIFY_LOG="${LOGDIR}/fortify_${FORTIFY_DATE}.log"
readonly SUPPORTED_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
readonly REQUIRED_DISK_SPACE=10485760  # 10GB in KB
COMMAND="${*,,}"
SKIP_HEAVY_SCANS="false"
SSH_HARDENING="true"
AUTO_UPDATES="true"

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-heavy-scans) SKIP_HEAVY_SCANS="true"; shift ;;
        --no-ssh-hardening) SSH_HARDENING="false"; shift ;;
        --no-auto-updates) AUTO_UPDATES="false"; shift ;;
        *) break ;;
    esac
done

# --- Helper Functions ---
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${FORTIFY_LOG}"; }
log_success() { echo -e "\e[32m[OK]\e[0m $1" | tee -a "${FORTIFY_LOG}"; }
log_warn() { echo -e "\e[33m[WARNING]\e[0m $1" | tee -a "${FORTIFY_LOG}"; }
log_error() { echo -e "\e[31m[ERROR]\e[0m $1" | tee -a "${FORTIFY_LOG}"; }
die() { log_error "FATAL: $1"; exit 1; }
check_root() { [[ "$(id -u)" -eq 0 ]] || die "This script must be run as root."; }
check_disk_space() {
    local available_space
    available_space=$(df --output=avail / | tail -n 1)
    [[ "${available_space}" -ge "${REQUIRED_DISK_SPACE}" ]] || die "Insufficient disk space. Required: 10GB, Available: $((available_space / 1024))MB"
}
check_ubuntu_version() {
    local version
    version=$(lsb_release -rs 2>/dev/null || echo "unknown")
    for supported in "${SUPPORTED_UBUNTU_VERSIONS[@]}"; do
        [[ "${version}" == "${supported}" ]] && return 0
    done
    die "Unsupported Ubuntu version: ${version}. Supported versions: ${SUPPORTED_UBUNTU_VERSIONS[*]}"
}
add_cron_job() {
    local job="$1"
    local cron_file
    cron_file=$(mktemp)
    (crontab -l 2>/dev/null || true) > "${cron_file}"
    if ! grep -F -q "${job}" "${cron_file}"; then
        echo "${job}" >> "${cron_file}"
        crontab "${cron_file}" || log_error "Failed to add cron job: ${job}"
    fi
    rm -f "${cron_file}"
}
heal_fail2ban() {
    if [[ -f /var/log/fail2ban.log ]] && grep -q "database disk image is malformed" /var/log/fail2ban.log; then
        log_warn "Fail2Ban database corrupted. Rebuilding..."
        rm -f /var/lib/fail2ban/fail2ban.sqlite3
        systemctl restart fail2ban >/dev/null 2>&1 || log_error "Failed to restart Fail2Ban"
    fi
}
heal_aide() {
    if [[ -f /var/lib/aide/aide.db.new ]]; then
        log_success "Finalizing AIDE database..."
        mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db || log_error "Failed to finalize AIDE database"
    fi
}
recommend_livepatch() {
    if ! command -v canonical-livepatch >/dev/null 2>&1 || ! canonical-livepatch status >/dev/null 2>&1; then
        log_warn "Canonical Livepatch not detected. Consider enabling for zero-downtime kernel patches: https://ubuntu.com/security/livepatch"
    fi
}
backup_sshd_config() {
    local backup_file="/etc/ssh/sshd_config.bak.${FORTIFY_DATE}"
    cp /etc/ssh/sshd_config "${backup_file}" || log_error "Failed to backup SSHD config"
    log_success "Backed up SSHD config to ${backup_file}"
}
self_upgrade() {
    log "Starting self-upgrade..."
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        die "Installation directory not found: ${INSTALL_DIR}"
    fi
    cd "${INSTALL_DIR}" || die "Failed to access installation directory"
    if ! git pull origin main >> "${FORTIFY_LOG}" 2>&1; then
        log_warn "Git pull failed; check repository status manually."
    else
        chmod +x fortify.sh
        log_success "Lordmoritz Fortify script updated successfully!"
        echo -e "\n🛡️ Please re-run 'sudo lordmoritz-fortify lordmoritz fortify me' to apply the updated script."
        exit 0
    fi
}
verify_command() {
    if [[ "${COMMAND}" == *"lordmoritz upgrade me"* ]]; then
        self_upgrade
    elif [[ "${COMMAND}" != *"lordmoritz fortify me"* ]]; then
        echo -e "\nUsage:"
        echo -e "  sudo lordmoritz-fortify lordmoritz fortify me   (for full hardening)"
        echo -e "  sudo lordmoritz-fortify lordmoritz upgrade me   (to self-update this script)"
        echo -e "\nOptional flags:"
        echo -e "  --skip-heavy-scans     (skip nightly scans for low-resource systems)"
        echo -e "  --no-ssh-hardening     (disable SSH hardening)"
        echo -e "  --no-auto-updates      (disable automatic security updates)"
        exit 1
    fi
}
install_apt_packages() {
    local retries=3
    local attempt=1
    log "Updating package lists..."
    while [[ ${attempt} -le ${retries} ]]; do
        if apt update >> "${FORTIFY_LOG}" 2>&1; then
            break
        fi
        log_warn "APT update failed (attempt ${attempt}/${retries}). Retrying..."
        ((attempt++))
        sleep 5
    done
    [[ ${attempt} -le ${retries} ]] || die "Failed to update APT after ${retries} attempts"
    log "Installing security packages..."
    apt install -y clamav rkhunter aide fail2ban ufw unattended-upgrades >> "${FORTIFY_LOG}" 2>&1 || die "Failed to install required packages"
}

# --- Main Execution ---
verify_command
check_root
check_ubuntu_version
check_disk_space

# Setup logging
mkdir -p "${LOGDIR}" || die "Failed to create log directory: ${LOGDIR}"
chown root:adm "${LOGDIR}"
chmod 750 "${LOGDIR}"
touch "${FORTIFY_LOG}" || die "Failed to create log file: ${FORTIFY_LOG}"

log_success "=== [Lordmoritz Fortify v2.1.1 Start] ==="

# Phase 1: Install Essentials
install_apt_packages

# Phase 2: Configure UFW Firewall
log "Configuring UFW firewall..."
ufw allow OpenSSH >> "${FORTIFY_LOG}" 2>&1 || log_error "Failed to allow OpenSSH in UFW"
if ! ufw --force enable >> "${FORTIFY_LOG}" 2>&1; then
    log_warn "UFW enable failed; firewall may already be active"
fi

# Phase 3: Schedule Nightly Scans
if [[ "${SKIP_HEAVY_SCANS}" != "true" ]]; then
    log "Scheduling nightly security scans..."
    add_cron_job "0 0 * * * /usr/bin/clamscan -r --bell -i / > ${LOGDIR}/clamav-nightly-\$(date +%Y%m%d).log 2>&1"
    add_cron_job "30 0 * * * /usr/bin/rkhunter --update --quiet >> ${LOGDIR}/rkhunter-update-\$(date +%Y%m%d).log 2>&1"
    add_cron_job "0 1 * * * /usr/bin/rkhunter --check --skip-keypress --report-warnings-only > ${LOGDIR}/rkhunter-nightly-\$(date +%Y%m%d).log 2>&1"
    add_cron_job "0 2 * * * /bin/systemctl restart fail2ban >> ${LOGDIR}/fail2ban-restart-\$(date +%Y%m%d).log 2>&1"
    add_cron_job "0 3 * * 0 /usr/bin/aide --check > ${LOGDIR}/aide-weekly-\$(date +%Y%m%d).log 2>&1"
fi

# Phase 4: AIDE Configuration
log "Configuring AIDE monitoring..."
mkdir -p /etc/aide/aide.conf.d/ || die "Failed to create AIDE config directory"
cat <<EOF > "${CUSTOM_AIDE_CONF}"
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
!/var/log
EOF
chmod 644 "${CUSTOM_AIDE_CONF}"
log "Initializing AIDE database..."
if ! aideinit --yes >> "${FORTIFY_LOG}" 2>&1; then
    log_warn "AIDE initialization had warnings; check logs"
fi

# Phase 5: SSH Hardening
if [[ "${SSH_HARDENING}" == "true" ]]; then
    log "Hardening SSH settings..."
    backup_sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config || log_error "Failed to update PermitRootLogin"
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config || log_error "Failed to update PasswordAuthentication"
    if ! systemctl restart sshd >> "${FORTIFY_LOG}" 2>&1; then
        log_warn "SSH restart failed; manual intervention required"
    fi
fi

# Phase 6: Auto Security Updates
if [[ "${AUTO_UPDATES}" == "true" ]]; then
    log "Configuring automatic security updates..."
    if ! dpkg-reconfigure -f noninteractive unattended-upgrades >> "${FORTIFY_LOG}" 2>&1; then
        log_error "Failed to configure unattended-upgrades"
    fi
    echo 'Unattended-Upgrade::Automatic-Reboot "true";' > /etc/apt/apt.conf.d/50unattended-upgrades
fi

# Phase 7: Healing and Recommendations
heal_fail2ban
heal_aide
recommend_livepatch

# Final Summary
log_success "[Lordmoritz Fortification Completed]"
echo "Reports Directory: ${LOGDIR}"
echo "Review nightly scan logs and consider enabling Canonical Livepatch: https://ubuntu.com/security/livepatch"
exit 0