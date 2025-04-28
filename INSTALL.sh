#!/bin/bash
# ======================================================
# INSTALL.sh
# Installer for Lordmoritz Fortify Script v2.1.2
# Author: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# Purpose: Install or update Lordmoritz Fortify and set up execution
# License: MIT
# Last Updated: 2025-04-28
# ======================================================

set -e  # Exit on error
set -u  # Treat unset variables as errors

# --- Configuration ---
readonly REPO_URL="https://github.com/gentzycode/lordmoritz-fortify.git"
readonly INSTALL_DIR="/opt/lordmoritz-fortify"
readonly SCRIPT_NAME="lordmoritz-fortify.sh"
readonly SYMLINK_PATH="/usr/local/bin/lordmoritz-fortify"
readonly REQUIRED_PACKAGES=("git")

# --- Colors ---
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# --- Helper Functions ---
log() { echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
log_success() { echo -e "${GREEN}[OK] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
check_root() { [[ "$(id -u)" -eq 0 ]] || log_error "This script must be run as root (sudo)."; }
check_packages() {
    local missing=()
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        command -v "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log "Installing required package(s): ${missing[*]}"
        apt update >/dev/null 2>&1 || log_error "Failed to update APT repositories"
        apt install -y "${missing[@]}" >/dev/null 2>&1 || log_error "Failed to install required packages: ${missing[*]}"
    fi
}

clone_or_update_repo() {
    if [[ ! -d "${INSTALL_DIR}" ]]; then
        log "Cloning Lordmoritz Fortify repository..."
        git clone "${REPO_URL}" "${INSTALL_DIR}" >/dev/null 2>&1 || log_error "Failed to clone repository"
    else
        log "Updating existing Lordmoritz Fortify repository..."
        cd "${INSTALL_DIR}" || log_error "Failed to access ${INSTALL_DIR}"
        if ! git pull origin main >/dev/null 2>&1; then
            log_error "Git pull failed. Repository might be corrupted or offline."
        fi
    fi
}

validate_script_existence() {
    if [[ ! -f "${INSTALL_DIR}/${SCRIPT_NAME}" ]]; then
        log_error "Main script ${SCRIPT_NAME} not found in ${INSTALL_DIR}."
    fi
}

setup_symlink() {
    log "Setting up symlink for easy execution..."
    if [[ -L "${SYMLINK_PATH}" ]]; then
        rm -f "${SYMLINK_PATH}"
    fi
    ln -sf "${INSTALL_DIR}/${SCRIPT_NAME}" "${SYMLINK_PATH}" || log_error "Failed to create symlink at ${SYMLINK_PATH}"
}

# --- Welcome ---
clear
echo -e "${GREEN}Lordmoritz Fortify Installer v2.1.2${NC}"
echo "==================================="

# --- Pre-checks ---
check_root
check_packages

# --- Clone or Update Repository ---
clone_or_update_repo

# --- Validate Main Script ---
validate_script_existence

# --- Set Executable Permission ---
chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}" || log_error "Failed to set executable permission on ${SCRIPT_NAME}"

# --- Create Symlink ---
setup_symlink

# --- Completion ---
echo ""
log_success "Installation complete!"
echo "==================================="
echo ""
echo "📌 To fortify your system, run:"
echo ""
echo "    sudo lordmoritz-fortify lordmoritz fortify me"
echo ""
echo "Optional flags:"
echo "    --skip-heavy-scans     (Skip resource-heavy nightly scans)"
echo "    --no-ssh-hardening     (Disable SSH configuration hardening)"
echo "    --no-auto-updates      (Disable automatic security updates)"
echo ""
echo "📚 Documentation:"
echo "    https://github.com/gentzycode/lordmoritz-fortify"
echo ""
echo "🚀 To update the script anytime in the future, run:"
echo ""
echo "    sudo lordmoritz-fortify lordmoritz upgrade me"
echo ""
echo "🛡️ Happy Hardening!"
echo ""
exit 0
