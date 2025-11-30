#!/bin/bash

# Zurg Update Script
# Adapted for Sailarr setup

echo "🚀 Zurg Update Started!"

# Check if running from the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the Sailarr root directory."
    exit 1
fi

echo "🛑 Stopping dependent containers..."
# Stop services that depend on Zurg/Rclone
docker-compose stop plex radarr sonarr prowlarr autoscan overseerr recyclarr blackhole rclone

echo "🛑 Stopping Zurg..."
docker-compose stop zurg

echo "🧹 Pruning old Zurg images..."
docker image prune -f --filter "label=com.docker.compose.service=zurg"

echo "🧹 Pruning unused volumes (optional, uncomment if needed)..."
# docker volume prune -f

echo "🔄 Pulling latest Zurg image..."
docker-compose pull zurg

echo "🚀 Starting Zurg..."
docker-compose up -d zurg

echo "⏳ Waiting for Zurg to initialize (10s)..."
sleep 10

echo "🚀 Starting Rclone..."
docker-compose up -d rclone

echo "⏳ Waiting for Rclone mount (5s)..."
sleep 5

echo "🚀 Starting remaining services..."
docker-compose up -d plex radarr sonarr prowlarr autoscan overseerr recyclarr blackhole

echo "✅ Update Complete!"
