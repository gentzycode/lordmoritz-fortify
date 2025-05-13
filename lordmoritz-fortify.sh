#!/bin/bash
# ======================================================
# Lordmoritz Fortify Script - Ultimate Auto-Hardening v2.1.5
# Author: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# Purpose: Fully automate Ubuntu VM hardening, monitoring, healing, and self-upgrading
# License: MIT
# Last Updated: 2025-05-13 22:58 WAT
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
readonly UFW_PORTS=(
    "OpenSSH:OpenSSH:tcp:SSH access"
    "HTTP:80:tcp:Web server (HTTP)"
    "HTTPS:443:tcp:Web server (HTTPS)"
    "Webmin:10000:tcp:Webmin control panel"
    "Usermin:20000:tcp:Usermin user interface"
    "FileManager:12320:tcp:Virtualmin File Manager (optional)"
    "NodeJS:3001:tcp:Custom Node.js application port"
    "SMTP:25:tcp:Mail (SMTP)"
    "SMTPS:465:tcp:Mail (SMTP over SSL)"
    "SMTP_STARTTLS:587:tcp:Mail (SMTP with STARTTLS)"
    "POP3:110:tcp:Mail (POP3)"
    "POP3S:995:tcp:Mail (POP3 over SSL)"
    "IMAP:143:tcp:Mail (IMAP)"
    "IMAPS:993:tcp:Mail (IMAP over SSL)"
    "FTP_Data:20:tcp:FTP data transfer (optional)"
    "FTP_Control:21:tcp:FTP control (optional)"
    "FTP_Passive:10000-10100:tcp:Passive FTP ports for ProFTPD (optional)"
    "DNS:53:tcp:DNS server (if handling domain resolving)"
    "DNS_UDP:53:udp:DNS server (UDP)"
    "MySQL:3306:tcp:MySQL database (restrict to specific IPs if possible)"
    "PostgreSQL:5432:tcp:PostgreSQL database (restrict to specific IPs if possible)"
    "ICMP:proto_icmp:proto:Allow ICMP ping (optional)"
)
COMMAND="${*,,}"
SKIP_HEAVY_SCANS="false"
SSH_HARDENING="true"
AUTO_UPDATES="true"
UNATTENDED_MODE="false"
DRY_RUN="false"

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-heavy-scans) SKIP_HEAVY_SCANS="true"; shift ;;
        --no-ssh-hardening) SSH_HARDENING="false"; shift ;;
        --no-auto-updates) AUTO_UPDATES="false"; shift ;;
        --unattended) UNATTENDED_MODE="true"; shift ;;
        --dry-run) DRY_RUN="true"; shift ;;
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
    # Check for latest version
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/gentzycode/lordmoritz-fortify/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    if [[ "${latest_version}" != "v2.1.5" ]]; then
        log_warn "Newer version ${latest_version} available! Consider updating manually."
    fi
    if ! git pull origin main >> "${FORTIFY_LOG}" 2>&1; then
        log_warn "Git pull failed; check repository status manually."
    else
        chmod +x lordmoritz-fortify.sh
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
        echo -e "  --unattended           (enable all firewall ports without prompting)"
        echo -e "  --dry-run              (simulate actions without applying changes)"
        exit 1
    fi
}
install_apt_packages() {
    local retries=3
    local attempt=1
    log "Updating package lists..."
    spinner_start
    while [[ ${attempt} -le ${retries} ]]; do
        if apt update >> "${FORTIFY_LOG}" 2>&1; then
            spinner_stop
            break
        fi
        log_warn "APT update failed (attempt ${attempt}/${retries}). Retrying..."
        ((attempt++))
        sleep 5
    done
    [[ ${attempt} -le ${retries} ]] || die "Failed to update APT after ${retries} attempts"
    log "Installing security packages..."
    spinner_start
    if ! apt install -y clamav rkhunter aide fail2ban ufw unattended-upgrades >> "${FORTIFY_LOG}" 2>&1; then
        spinner_stop
        die "Failed to install required packages"
    fi
    spinner_stop
}
configure_ufw_ports() {
    local enabled_ports=()
    local skipped_ports=()

    log "Configuring UFW ports..."

    # Backup current UFW rules
    local ufw_backup="/etc/ufw/ufw.bak.${FORTIFY_DATE}"
    if [[ "${DRY_RUN}" != "true" ]]; then
        cp -r /etc/ufw "${ufw_backup}" || log_error "Failed to backup UFW rules"
        log_success "Backed up UFW rules to ${ufw_backup}"
    else
        log "Dry Run: Would back up UFW rules to ${ufw_backup}"
    fi

    # Ensure UFW is enabled
    if ! ufw status | grep -q "Status: active"; then
        spinner_start
        if [[ "${DRY_RUN}" != "true" ]]; then
            ufw --force enable >> "${FORTIFY_LOG}" 2>&1 || die "Failed to enable UFW"
        else
            log "Dry Run: Would enable UFW"
        fi
        spinner_stop
    fi

    for port_entry in "${UFW_PORTS[@]}"; do
        IFS=':' read -r name port proto desc <<< "${port_entry}"
        local rule=""
        if [[ "${proto}" == "proto" ]]; then
            rule="proto ${port}"
        else
            rule="${port}/${proto}"
        fi

        # Skip OpenSSH since it's already allowed
        [[ "${name}" == "OpenSSH" ]] && continue

        # In unattended mode, enable all ports
        if [[ "${UNATTENDED_MODE}" == "true" ]]; then
            spinner_start
            if [[ "${DRY_RUN}" != "true" ]]; then
                if ufw allow "${rule}" >> "${FORTIFY_LOG}" 2>&1; then
                    enabled_ports+=("${name} (${rule})")
                else
                    log_error "Failed to allow ${name} (${rule})"
                    skipped_ports+=("${name} (${rule})")
                fi
            else
                log "Dry Run: Would allow ${name} (${rule})"
                enabled_ports+=("${name} (${rule})")
            fi
            spinner_stop
            continue
        fi

        # Interactive mode: prompt user
        read -p "Allow ${name} (${desc}, ${rule})? [y/N]: " answer
        answer="${answer,,}"
        if [[ "${answer}" == "y" || "${answer}" == "yes" ]]; then
            spinner_start
            if [[ "${DRY_RUN}" != "true" ]]; then
                if ufw allow "${rule}" >> "${FORTIFY_LOG}" 2>&1; then
                    enabled_ports+=("${name} (${rule})")
                else
                    log_error "Failed to allow ${name} (${rule})"
                    skipped_ports+=("${name} (${rule})")
                fi
            else
                log "Dry Run: Would allow ${name} (${rule})"
                enabled_ports+=("${name} (${rule})")
            fi
            spinner_stop

            # Special handling for MySQL and PostgreSQL
            if [[ "${name}" == "MySQL" || "${name}" == "PostgreSQL" ]]; then
                read -p "Restrict ${name} to a specific IP? (Enter IP or leave blank for any): " ip
                if [[ -n "${ip}" && "${DRY_RUN}" != "true" ]]; then
                    ufw allow from "${ip}" to any port "${port}" proto "${proto}" >> "${FORTIFY_LOG}" 2>&1 || log_error "Failed to restrict ${name} to ${ip}"
                    log_success "Restricted ${name} to ${ip}"
                elif [[ -n "${ip}" && "${DRY_RUN}" == "true" ]]; then
                    log "Dry Run: Would restrict ${name} to ${ip}"
                fi
            fi
        else
            log "Skipping ${name} (${rule})"
            skipped_ports+=("${name} (${rule})")
        fi
    done

    # Apply SSH rate limiting
    if [[ "${SSH_HARDENING}" == "true" ]]; then
        spinner_start
        if [[ "${DRY_RUN}" != "true" ]]; then
            ufw limit OpenSSH >> "${FORTIFY_LOG}" 2>&1 || log_error "Failed to limit OpenSSH"
        else
            log "Dry Run: Would limit OpenSSH"
        fi
        spinner_stop
    fi

    # Reload UFW
    spinner_start
    if [[ "${DRY_RUN}" != "true" ]]; then
        ufw reload >> "${FORTIFY_LOG}" 2>&1 || log_error "Failed to reload UFW"
    else
        log "Dry Run: Would reload UFW"
    fi
    spinner_stop

    # Log and display summary
    log "UFW Configuration Summary:"
    if [[ ${#enabled_ports[@]} -gt 0 ]]; then
        log "\e[32mEnabled ports:\e[0m"
        for port in "${enabled_ports[@]}"; do
            log "  - \e[32m${port}\e[0m"
        done
    fi
    if [[ ${#skipped_ports[@]} -gt 0 ]]; then
        log "\e[33mSkipped ports:\e[0m"
        for port in "${skipped_ports[@]}"; do
            log "  - \e[33m${port}\e[0m"
        done
    fi

    # Display current UFW status
    log "Current UFW status:"
    ufw status numbered >> "${FORTIFY_LOG}" 2>&1

    # Provide security advice
    log "Firewall Security Recommendations:"
    log "  - Restrict MySQL/PostgreSQL (ports 3306/5432) to specific IPs if possible (e.g., 'ufw allow from <IP> to any port 3306')."
    log "  - Verify the passive FTP port range (10000-10100) matches your ProFTPD configuration."
    log "  - Disable ICMP (ping) if not needed for monitoring."
    log "  - Regularly review open ports with 'ufw status numbered' and remove unused rules."
}

# --- New Helper Functions ---
spinner_start() {
    local pid=$!
    local spin='-\|/'
    local i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\rProcessing... ${spin:$i:1}"
        sleep 0.1
    done
    printf "\r"
}

# --- ASCII Art Banner ---
print_banner() {
    echo -e "\e[1;34m"
    echo "========================================="
    echo "   Lordmoritz Fortify v2.1.5 ⚡"
    echo "   Ultimate Auto-Hardening Script"
    echo "========================================="
    echo -e "\e[0m"
}

# --- Main Execution ---
print_banner
verify_command
check_root
check_ubuntu_version
check_disk_space

# Setup logging
mkdir -p "${LOGDIR}" || die "Failed to create log directory: ${LOGDIR}"
chown root:adm "${LOGDIR}"
chmod 750 "${LOGDIR}"
touch "${FORTIFY_LOG}" || die "Failed to create log file: ${FORTIFY_LOG}"

log_success "=== [Lordmoritz Fortify v2.1.5 Start] ==="

# Phase 1: Install Essentials
install_apt_packages

# Phase 2: Configure UFW Firewall
configure_ufw_ports

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