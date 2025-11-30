# Directory Structure

This document explains the directory structure for the Sailarr media center.

## Overview

```
/mediacenter/
├── configs/              # Configuration files for all services
├── data/                 # Data storage and media files
├── docker-compose.yml    # Main Docker Compose file
├── .env                  # Environment variables (create from .env.example)
├── .env.example          # Example environment file
├── setup.sh              # Setup script
├── manage.sh             # Management script
├── README.md             # Main documentation
└── CONFIGURATION.md      # Configuration guide
```

## Configs Directory

Configuration files and application data for each service.

```
configs/
├── zurg/
│   ├── config.yml        # Zurg configuration
│   ├── rclone.conf       # Rclone configuration
│   └── data/             # Zurg data directory
├── plex/                 # Plex configuration and metadata
├── radarr/               # Radarr configuration
├── sonarr/               # Sonarr configuration
├── prowlarr/             # Prowlarr configuration
├── autoscan/             # Autoscan configuration
├── recyclarr/            # Recyclarr configuration
│   └── recyclarr.yml     # Recyclarr config file
├── overseerr/            # Overseerr configuration
└── blackhole/
    └── logs/             # Blackhole log files

scripts/                  # Helper scripts (maintenance, updates)

```

### Important Notes:

- **configs/zurg/config.yml** - Must contain your Real-Debrid API token
- **configs/zurg/rclone.conf** - Rclone configuration for mounting Zurg
- All other config directories are auto-populated by the services on first run

## Data Directory

Media files, symlinks, and temporary data.

```
data/
├── plex/                 # Plex media libraries
│   ├── Movies/           # Movies library
│   └── TV/               # TV Shows library
├── symlinks/             # Symlinks created by blackhole
│   ├── radarr/
│   │   ├── completed/    # Completed downloads (watch folder)
│   │   └── processing/   # Processing downloads (torrent folder)
│   ├── sonarr/
│   │   ├── completed/
│   │   └── processing/
├── remote/
│   └── realdebrid/       # Real-Debrid mount point (via rclone)
│       └── __all__/      # All torrents (used by blackhole)
└── local/
    └── transcodes/
        └── plex/         # Plex transcoding directory
```

### Important Notes:

- **data/plex/** - Contains symlinks to actual media on Real-Debrid
- **data/symlinks/** - Blackhole creates symlinks here, then *arr apps import them
- **data/remote/realdebrid/** - Mounted Real-Debrid content (read-only)
- **data/local/transcodes/plex/** - Temporary transcoding files

## Volume Mappings

All services use consistent volume mappings to ensure symlinks work correctly.

### Critical Mapping: /mnt:/mnt

All containers that need to access symlinks must have this mapping:

```yaml
volumes:
  - /mnt:/mnt
```

This ensures that symlinks created by blackhole can be read by Plex and the *arr apps.

### Service-Specific Mappings

**Zurg:**
- `./configs/zurg/config.yml:/app/config.yml` - Configuration
- `./configs/zurg/data:/app/data` - Data directory

**Rclone:**
- `./data/remote/realdebrid:/data:rshared` - Mount point (shared)
- `./configs/zurg/rclone.conf:/config/rclone/rclone.conf:ro` - Config (read-only)

**Plex:**
- `./configs/plex:/config` - Configuration
- `./data/plex:/data/plex` - Media libraries
- `./data/local/transcodes/plex:/transcode` - Transcoding
- `./data/remote/realdebrid:/data/remote/realdebrid:ro` - Real-Debrid (read-only)

**Radarr/Sonarr:**
- `./configs/radarr:/config` - Configuration
- `./data/plex:/data/plex` - Media libraries
- `./data/symlinks/radarr:/data/symlinks/radarr` - Symlinks
- `./data/remote/realdebrid:/data/remote/realdebrid:ro` - Real-Debrid (read-only)

**Blackhole:**
- `./data/remote/realdebrid:/data/remote/realdebrid:ro` - Real-Debrid (read-only)
- `./data/symlinks:/data/symlinks` - Symlinks (read-write)
- `./configs/blackhole/logs:/app/logs` - Logs

## Permissions

All directories must have the correct permissions for the services to work.

### PUID and PGID

All services run with the same PUID and PGID (set in `.env`):

```bash
# Get your PUID and PGID
id

# Output example:
# uid=1000(username) gid=1000(username)
```

Set these in `.env`:

```env
PUID=1000
PGID=1000
```

### Setting Permissions

```bash
# Set ownership (replace 1000:1000 with your PUID:PGID)
sudo chown -R 1000:1000 /mediacenter

# Set permissions
sudo chmod -R 775 /mediacenter
```

## Data Flow

Understanding how data flows through the system:

1. **User adds content** in Radarr/Sonarr
2. **Radarr/Sonarr searches** via Prowlarr indexers
3. **User selects release**, Radarr/Sonarr saves `.magnet` file to `/data/symlinks/radarr/processing/`
4. **Blackhole watches** the processing folder
5. **Blackhole checks** if torrent is cached on Real-Debrid
6. **If cached**, blackhole adds to Real-Debrid and waits for it to appear in `/data/remote/realdebrid/__all__/`
7. **Blackhole creates symlink** from `/data/plex/Movies/` to the Real-Debrid file
8. **Blackhole moves** the `.magnet` file to `/data/symlinks/radarr/completed/`
9. **Radarr/Sonarr detects** completed download and imports it
10. **Plex scans** the library and adds the new content

## Cleanup

### Broken Symlinks

Over time, symlinks may become broken (if content is removed from Real-Debrid).

Clean them up with:

```bash
./manage.sh cleanup
```

Or manually:

```bash
# Find and remove broken symlinks
find /mediacenter/data/plex -xtype l -delete
```

### Old Logs

Blackhole logs can grow over time:

```bash
# View log size
du -sh configs/blackhole/logs/

# Clean old logs
rm configs/blackhole/logs/*.log.old
```

### Docker Cleanup

Clean up Docker resources:

```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune
```

## Backup Recommendations

### What to Backup

**Critical (must backup):**
- `configs/` - All configuration files
- `.env` - Environment variables

**Optional:**
- `data/plex/` - Only if you want to preserve symlinks (they can be recreated)

**Don't backup:**
- `data/remote/realdebrid/` - This is a mount, not actual data
- `data/local/transcodes/` - Temporary files

### Backup Script Example

```bash
#!/bin/bash
# Backup critical configs

BACKUP_DIR="/backup/sailarr-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup configs
tar -czf "$BACKUP_DIR/configs.tar.gz" /mediacenter/configs/

# Backup .env
cp /mediacenter/.env "$BACKUP_DIR/"

# Backup docker-compose.yml
cp /mediacenter/docker-compose.yml "$BACKUP_DIR/"

echo "Backup complete: $BACKUP_DIR"
```

## Troubleshooting

### Permissions Issues

```bash
# Check ownership
ls -la /mediacenter/

# Fix ownership
sudo chown -R 1000:1000 /mediacenter
sudo chmod -R 775 /mediacenter
```

### Mount Issues

```bash
# Check if mount is active
./manage.sh verify-mount

# Check rclone logs
docker-compose logs rclone

# Restart rclone
docker-compose restart rclone
```

### Symlink Issues

```bash
# Check symlinks
ls -la /mediacenter/data/plex/Movies/

# Check blackhole logs
docker-compose logs blackhole

# Verify PUID/PGID match
docker-compose exec plex id
docker-compose exec radarr id
```

## Advanced: Custom Paths

If you want to use different paths, you'll need to update:

1. **docker-compose.yml** - All volume mappings
2. **.env** - Path-related variables
3. **configs/zurg/config.yml** - If changing mount paths
4. **Service configurations** - Root folders in Radarr/Sonarr

> **Warning:** Changing paths after initial setup can break existing symlinks and configurations.
