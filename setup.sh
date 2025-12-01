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
mkdir -p "${BASE_DIR}"/{configs,data}

# Create config directories
echo "📁 Creating config directories..."
# Riven
mkdir -p "${BASE_DIR}"/configs/riven/{data,frontend,db}
# Other services
mkdir -p "${BASE_DIR}"/configs/{plex,prowlarr,overseerr}

# Create data directories
echo "📁 Creating data directories..."
mkdir -p "${BASE_DIR}"/data/plex/{"Movies","TV"}
mkdir -p "${BASE_DIR}"/data/riven/mount
mkdir -p "${BASE_DIR}"/data/local/transcodes/plex

echo ""
echo "✅ Directory structure created successfully!"
echo ""

# Copy files
echo "📁 Copying configuration files..."
cp docker-compose.yml "${BASE_DIR}/"
cp manage.sh "${BASE_DIR}/"
chmod +x "${BASE_DIR}/manage.sh"

if [ ! -f "${BASE_DIR}/.env" ]; then
    echo "Creating .env from .env.example..."
    cp .env.example "${BASE_DIR}/.env"
    
    # Generate Riven Backend API Key
    echo "Generating Riven Backend API Key..."
    if command -v openssl &> /dev/null; then
        RIVEN_KEY=$(openssl rand -hex 16)
    else
        # Fallback to tr/urandom
        RIVEN_KEY=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)
    fi
    
    # Update .env with the key
    # Check if RIVEN_BACKEND_API_KEY exists in .env, if not append it
    if grep -q "RIVEN_BACKEND_API_KEY=" "${BASE_DIR}/.env"; then
        sed -i.bak "s/RIVEN_BACKEND_API_KEY=.*/RIVEN_BACKEND_API_KEY=${RIVEN_KEY}/" "${BASE_DIR}/.env" && rm "${BASE_DIR}/.env.bak"
    else
        echo "RIVEN_BACKEND_API_KEY=${RIVEN_KEY}" >> "${BASE_DIR}/.env"
    fi
    echo "✅ Generated and configured Riven API Key"
else
    echo "⚠️  .env already exists, skipping creation and key generation."
fi

echo "✅ Files copied successfully!"
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
    chown -R "${CURRENT_PUID}:${CURRENT_PGID}" "${BASE_DIR}"
    chmod -R 775 "${BASE_DIR}"
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
echo "1. Go to the media center directory:"
echo "   cd ${BASE_DIR}"
echo ""
echo "2. Configure your .env file (add Real-Debrid API key, etc):"
echo "   nano .env"
echo ""
echo "3. Start the core services to configure Riven:"
echo "   ./manage.sh core"
echo ""
echo "================================================"

echo "✅ Setup complete! Directory structure created at ${BASE_DIR}"
