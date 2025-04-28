#!/bin/bash
# ======================================================
# INSTALL.sh
# Installer for Lordmoritz Fortify Script v2.1.2 (Improved)
# Author: Chinonso Okoye (Lordmoritz / Gentmorris / Gentzycode)
# License: MIT
# Last Updated: 2025-04-28
# ======================================================

set -e
set -u

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
        apt update >/dev/null 2>&1 || log_error "Failed to update APT"
        apt install -y "${missing[@]}" >/dev/null 2>&1 || log_error "Failed to install required packages"
    fi
}

clone_or_update_repo() {
    if [[ -d "${INSTALL_DIR}" ]]; then
        log "Existing installation detected. Pulling latest updates..."
        cd "${INSTALL_DIR}" || log_error "Failed to access ${INSTALL_DIR}"
        if ! git pull origin main >/dev/null 2>&1; then
            log_error "Git pull failed. Please verify network or repo status."
        fi
    else
        log "Cloning Lordmoritz Fortify repository into /opt..."
        git clone "${REPO_URL}" "${INSTALL_DIR}" >/dev/null 2>&1 || log_error "Failed to clone repository"
    fi
}

setup_symlink() {
    log "Setting up symlink for easy execution..."
    chmod +x "${INSTALL_DIR}/${SCRIPT_NAME}" || log_error "Failed to set executable permissions on ${SCRIPT_NAME}"
    ln -sf "${INSTALL_DIR}/${SCRIPT_NAME}" "${SYMLINK_PATH}" || log_error "Failed to create symlink at ${SYMLINK_PATH}"
}

# --- Welcome ---
clear
echo -e "${GREEN}Lordmoritz Fortify Installer v2.1.2${NC}"
echo "==================================="

# --- Pre-checks ---
check_root
check_packages

# --- Detect current folder ---
CURRENT_DIR=$(pwd)
if [[ "${CURRENT_DIR}" == *"lordmoritz-fortify"* && -f "./${SCRIPT_NAME}" ]]; then
    log "Installer is running inside the cloned repository."
    log "Skipping git pull. Setting up permissions and symlink only."
    chmod +x "./${SCRIPT_NAME}" || log_error "Failed to set executable permissions on ${SCRIPT_NAME}"
    ln -sf "${CURRENT_DIR}/${SCRIPT_NAME}" "${SYMLINK_PATH}" || log_error "Failed to create symlink."
else
    clone_or_update_repo
    setup_symlink
fi

# --- Completion ---
echo ""
log_success "Installation complete!"
echo "==================================="
echo ""
echo "📌 To fortify your system, run:"
echo ""
echo "    sudo lordmoritz-fortify lordmoritz fortify me"
echo ""
echo "📚 Documentation:"
echo "    https://github.com/gentzycode/lordmoritz-fortify"
echo ""
echo "🚀 Future updates:"
echo ""
echo "    sudo lordmoritz-fortify lordmoritz upgrade me"
echo ""
echo "🛡️ Happy Hardening!"
echo ""
exit 0
