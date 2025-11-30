#!/bin/bash

# Sailarr Media Center - Setup Script
# This script creates the necessary directory structure for the media center

set -e

echo "================================================"
echo "Sailarr Media Center - Directory Setup"
echo "================================================"
echo ""

# Base directory
BASE_DIR="/mediacenter"

echo "Creating directory structure in ${BASE_DIR}..."
echo ""

# Create base directories
echo "📁 Creating base directories..."
mkdir -p "${BASE_DIR}"/{configs,data,scripts}

# Create config directories
echo "📁 Creating config directories..."
mkdir -p "${BASE_DIR}"/configs/{zurg/data,plex,radarr,sonarr,bazarr,prowlarr,autoscan,overseerr,blackhole/logs,recyclarr}

# Create data directories
echo "📁 Creating data directories..."
mkdir -p "${BASE_DIR}"/data/plex/{"Movies","TV"}
mkdir -p "${BASE_DIR}"/data/symlinks/{radarr,sonarr}/{completed,processing}
mkdir -p "${BASE_DIR}"/data/remote/realdebrid
mkdir -p "${BASE_DIR}"/data/local/transcodes/plex

# Create default Zurg config if it doesn't exist
if [ ! -f "${BASE_DIR}/configs/zurg/config.yml" ]; then
    echo "📝 Creating default Zurg config..."
    cat > "${BASE_DIR}/configs/zurg/config.yml" <<EOL
zurg: v1
token: ENTER_YOUR_TOKEN_HERE
host: "[::]"
port: 9999
concurrent_workers: 32
check_for_changes_every_secs: 10
ignore_renames: true
retain_rd_torrent_name: true
retain_rd_torrent_numbering: true
EOL
fi

echo ""
echo "✅ Directory structure created successfully!"
echo ""

# Get current user's PUID and PGID
if [ -n "$SUDO_USER" ]; then
    CURRENT_PUID=$(id -u "$SUDO_USER")
    CURRENT_PGID=$(id -g "$SUDO_USER")
    echo "Running with sudo, using original user: $SUDO_USER"
else
    CURRENT_PUID=$(id -u)
    CURRENT_PGID=$(id -g)
fi

echo "Current user PUID: ${CURRENT_PUID}"
echo "Current user PGID: ${CURRENT_PGID}"
echo ""

# Ask if user wants to set permissions
read -p "Set ownership to ${CURRENT_PUID}:${CURRENT_PGID}? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Setting permissions..."
    sudo chown -R "${CURRENT_PUID}:${CURRENT_PGID}" "${BASE_DIR}"
    sudo chmod -R 775 "${BASE_DIR}"
    echo "✅ Permissions set successfully!"
else
    echo "⚠️  Skipping permission setup. Remember to set permissions manually:"
    echo "   sudo chown -R ${CURRENT_PUID}:${CURRENT_PGID} ${BASE_DIR}"
    echo "   sudo chmod -R 775 ${BASE_DIR}"
fi

echo ""
echo "================================================"
echo "Directory Structure:"
echo "================================================"
tree -L 3 "${BASE_DIR}" 2>/dev/null || find "${BASE_DIR}" -maxdepth 3 -type d | sed 's|[^/]*/| |g'

echo ""
echo "================================================"
echo "Next Steps:"
echo "================================================"
echo "1. Copy .env.example to .env and configure:"
echo "   cp .env.example .env"
echo "   nano .env"
echo ""
echo "2. Add your Real-Debrid API token to:"
echo "   ${BASE_DIR}/configs/zurg/config.yml"
echo ""
echo "3. Start the services:"
echo "   docker-compose up -d"
echo ""
echo "================================================"

# Make scripts executable
if [ -f "${BASE_DIR}/manage.sh" ]; then
    chmod +x "${BASE_DIR}"/manage.sh
fi
if [ -f "${BASE_DIR}/scripts/zurgupdate.sh" ]; then
    chmod +x "${BASE_DIR}"/scripts/zurgupdate.sh
fi

echo "✅ Setup complete! Directory structure created at ${BASE_DIR}"
echo "📝 Next steps:"
echo "1. Copy .env.example to .env and configure it"
echo "2. Copy docker-compose.yml to ${BASE_DIR}"
echo "3. Copy manage.sh and scripts/ to ${BASE_DIR}"
echo "4. Run ./manage.sh core to start Zurg and Rclone"
