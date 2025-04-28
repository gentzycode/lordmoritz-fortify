# INSTALL.sh
# Installer for Lordmoritz Fortify Script

#!/bin/bash
set -e

REPO_URL="https://github.com/gentzycode/lordmoritz-fortify.git"
INSTALL_DIR="/opt/lordmoritz-fortify"
SCRIPT_NAME="fortify.sh"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Welcome
clear
echo -e "${GREEN}Lordmoritz Fortify Installer${NC}"
echo "==============================="

# Clone or update repo
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Cloning Fortify repository..."
    git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "Updating existing Fortify repository..."
    cd "$INSTALL_DIR"
    git pull origin main || true
fi

chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Symlink for easier usage
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" /usr/local/bin/lordmoritz-fortify

# Done
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo "==================================="
echo -e "\nTo use it, run: \n"
echo -e "    sudo lordmoritz-fortify lordmoritz fortify me\n"
echo -e "Optionally add: \n"
echo -e "    --skip-heavy-scans   (skip big scans if needed)\n"
echo ""
echo -e "Documentation: https://github.com/gentzycode/lordmoritz-fortify"
echo ""
exit 0
