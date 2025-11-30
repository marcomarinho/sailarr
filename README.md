# Sailarr Media Center Setup

A complete Plex + Real-Debrid media server setup using Zurg, the *arr stack, and blackhole downloader.

## 📁 Directory Structure

```
/mediacenter/
├── configs/
│   ├── zurg/
│   │   ├── config.yml
│   │   ├── rclone.conf
│   │   └── data/
│   ├── plex/
│   ├── radarr/
│   ├── sonarr/
│   ├── prowlarr/
│   ├── autoscan/
│   ├── recyclarr/
│   ├── overseerr/
│   └── blackhole/
│       ├── .env
│       └── logs/
├── data/
│   ├── plex/
│   │   ├── Movies/
│   │   └── TV/
│   ├── symlinks/
│   │   ├── radarr/
│   │   │   ├── completed/
│   │   │   └── processing/
│   │   └── sonarr/
│   │       ├── completed/
│   │       └── processing/
│   ├── remote/
│   │   └── realdebrid/
│   └── local/
│       └── transcodes/
│           └── plex/
├── docker-compose.yml
└── .env
```

## 📋 Prerequisites

- **Linux Server** (Ubuntu 22.04 recommended)
- **Docker** and **Docker Compose** installed
- **Real-Debrid Account** - [Sign up here](http://real-debrid.com)
- **PUID/PGID** - Run `id` in terminal to get your user/group IDs
- **Hardware**: 
  - Minimum 4GB RAM
  - 20GB storage for configs
  - Intel/AMD CPU with hardware transcoding support (optional)

## 🚀 Quick Start

### 1. Create Directory Structure

```bash
# Create base directories
mkdir -p /mediacenter/{configs,data}

# Create config directories
mkdir -p /mediacenter/configs/{zurg/data,plex,radarr,sonarr,prowlarr,autoscan,overseerr,blackhole/logs,recyclarr}

# Create data directories
mkdir -p /mediacenter/data/plex/{Movies,TV}
mkdir -p /mediacenter/data/symlinks/{radarr,sonarr}/{completed,processing}
mkdir -p /mediacenter/data/remote/realdebrid
mkdir -p /mediacenter/data/local/transcodes/plex

# Set permissions (replace 1000:1000 with your PUID:PGID)
sudo chown -R 1000:1000 /mediacenter
sudo chmod -R 775 /mediacenter
```

### 2. Configure Environment Variables

Copy the `.env.example` to `.env` and fill in your details:

```bash
cd /mediacenter
cp .env.example .env
nano .env
```

**Required variables:**
- `PUID` and `PGID` - Your user/group IDs (run `id` command)
- `TZ` - Your timezone (e.g., `America/New_York`)
- `REALDEBRID_API_KEY` - Get from https://real-debrid.com/apitoken

### 3. Configure Zurg

Edit the Zurg configuration:

```bash
nano /mediacenter/configs/zurg/config.yml
```

Add your Real-Debrid API token to the config file.

### 4. Start Services

```bash
cd /mediacenter

# Start Zurg and rclone first
docker-compose up -d zurg rclone

# Wait for Zurg to be healthy (check with docker-compose ps)
# Then start remaining services
docker-compose up -d
```

### 5. Verify Mount

```bash
# Check if Real-Debrid is mounted
ls -la /mediacenter/data/remote/realdebrid/

# You should see your Real-Debrid content
```

## 🔧 Service Configuration

### Access Web UIs

After starting the services, access them at:

- **Plex**: http://localhost:32400/web
- **Radarr**: http://localhost:7878
- **Sonarr**: http://localhost:8989
- **Prowlarr**: http://localhost:9696
- **Autoscan**: http://localhost:3030
- **Overseerr**: http://localhost:5055

### Recyclarr Setup

Recyclarr is configured to sync TRaSH guides quality profiles.
1. Edit `configs/recyclarr/recyclarr.yml`
2. Add your Radarr/Sonarr API keys
3. Run sync: `docker-compose run --rm recyclarr sync`

### Plex Setup

1. Go to http://localhost:32400/web
2. Sign in with your Plex account
3. Add libraries pointing to:
   - Movies: `/data/plex/Movies`
   - TV Shows: `/data/plex/TV`

### Prowlarr Setup

1. Access Prowlarr at http://localhost:9696
2. Add indexers (public trackers work fine with Real-Debrid)
3. Connect to Radarr and Sonarr instances

### Radarr/Sonarr Setup

1. **Root Folders**:
   - Radarr: `/data/plex/Movies`
   - Sonarr: `/data/plex/TV`

2. **Download Client** (Torrent Blackhole):
   - Name: `Blackhole`
   - Torrent Folder: `/data/symlinks/radarr/processing` (or sonarr)
   - Watch Folder: `/data/symlinks/radarr/completed` (or sonarr)
   - Save Magnet Files: Yes
   - Magnet File Extension: `.magnet`

3. **Connect to Prowlarr**:
   - Add Prowlarr API key in Settings > General

### Blackhole Configuration

The blackhole script automatically:
- Checks if torrents are cached on Real-Debrid
- Creates symlinks to the cached content
- Notifies *arr apps when ready for import

Configuration is in `/mediacenter/configs/blackhole/.env`

## 📊 Management Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f plex
docker-compose logs -f zurg
docker-compose logs -f blackhole
```

### Restart Services

```bash
# All services
docker-compose restart

# Specific service
docker-compose restart plex
```

### Stop Services

```bash
docker-compose down
```

### Update Services

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

## 🔍 Troubleshooting

### Zurg not mounting

```bash
# Check Zurg logs
docker-compose logs zurg

# Check rclone logs
docker-compose logs rclone

# Verify API token in configs/zurg/config.yml
```

### Symlinks not working

```bash
# Check blackhole logs
docker-compose logs blackhole

# Verify PUID/PGID match across all services
docker-compose exec plex id
docker-compose exec radarr id
```

### Plex not seeing files

1. Verify mount: `ls /mediacenter/data/remote/realdebrid/`
2. Check symlinks: `ls -la /mediacenter/data/plex/Movies/`
3. Trigger Plex scan manually or use Autoscan

### Permission Issues

```bash
# Fix permissions
sudo chown -R 1000:1000 /mediacenter
sudo chmod -R 775 /mediacenter
```

## 🎯 Post-Installation

1. **Configure Autoscan** - Automatically scan new content in Plex
2. **Set up Petio** - Request management system
3. **Configure quality profiles** in Radarr/Sonarr
4. **Add custom formats** for better release selection
5. **Set up notifications** in *arr apps

## 📚 Additional Resources

- [Sailarr Guide](https://savvyguides.wiki/sailarrsguide/)
- [Zurg Documentation](https://github.com/debridmediamanager/zurg-testing)
- [Blackhole Scripts](https://github.com/westsurname/scripts)
- [TRaSH Guides](https://trash-guides.info/) - Quality profiles and custom formats

## ⚠️ Important Notes
cp .env.example .env
nano .env
```

**Required variables:**
- `PUID` and `PGID` - Your user/group IDs (run `id` command)
- `TZ` - Your timezone (e.g., `America/New_York`)
- `REALDEBRID_API_KEY` - Get from https://real-debrid.com/apitoken

### 3. Configure Zurg

Edit the Zurg configuration:

```bash
nano /mediacenter/configs/zurg/config.yml
```

Add your Real-Debrid API token to the config file.

### 4. Start Services

```bash
cd /mediacenter

# Start Zurg and rclone first
docker-compose up -d zurg rclone

# Wait for Zurg to be healthy (check with docker-compose ps)
# Then start remaining services
docker-compose up -d
```

### 5. Verify Mount

```bash
# Check if Real-Debrid is mounted
ls -la /mediacenter/data/remote/realdebrid/

# You should see your Real-Debrid content
```

## 🔧 Service Configuration

### Access Web UIs

After starting the services, access them at:

- **Plex**: http://localhost:32400/web
- **Radarr**: http://localhost:7878
- **Sonarr**: http://localhost:8989
- **Prowlarr**: http://localhost:9696
- **Autoscan**: http://localhost:3030
- **Overseerr**: http://localhost:5055

### Recyclarr Setup

Recyclarr is configured to sync TRaSH guides quality profiles.
1. Edit `configs/recyclarr/recyclarr.yml`
2. Add your Radarr/Sonarr API keys
3. Run sync: `docker-compose run --rm recyclarr sync`

### Plex Setup

1. Go to http://localhost:32400/web
2. Sign in with your Plex account
3. Add libraries pointing to:
   - Movies: `/data/plex/Movies`
   - TV Shows: `/data/plex/TV`

### Prowlarr Setup

1. Access Prowlarr at http://localhost:9696
2. Add indexers (public trackers work fine with Real-Debrid)
3. Connect to Radarr and Sonarr instances

### Radarr/Sonarr Setup

1. **Root Folders**:
   - Radarr: `/data/plex/Movies`
   - Sonarr: `/data/plex/TV`

2. **Download Client** (Torrent Blackhole):
   - Name: `Blackhole`
   - Torrent Folder: `/data/symlinks/radarr/processing` (or sonarr)
   - Watch Folder: `/data/symlinks/radarr/completed` (or sonarr)
   - Save Magnet Files: Yes
   - Magnet File Extension: `.magnet`

3. **Connect to Prowlarr**:
   - Add Prowlarr API key in Settings > General

### Blackhole Configuration

The blackhole script automatically:
- Checks if torrents are cached on Real-Debrid
- Creates symlinks to the cached content
- Notifies *arr apps when ready for import

Configuration is in `/mediacenter/configs/blackhole/.env`

## 📊 Management Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f plex
docker-compose logs -f zurg
docker-compose logs -f blackhole
```

### Restart Services

```bash
# All services
docker-compose restart

# Specific service
docker-compose restart plex
```

### Stop Services

```bash
docker-compose down
```

### Update Services

```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

## 🔍 Troubleshooting

### Zurg not mounting

```bash
# Check Zurg logs
docker-compose logs zurg

# Check rclone logs
docker-compose logs rclone

# Verify API token in configs/zurg/config.yml
```

### Symlinks not working

```bash
# Check blackhole logs
docker-compose logs blackhole

# Verify PUID/PGID match across all services
docker-compose exec plex id
docker-compose exec radarr id
```

### Plex not seeing files

1. Verify mount: `ls /mediacenter/data/remote/realdebrid/`
2. Check symlinks: `ls -la /mediacenter/data/plex/Movies/`
3. Trigger Plex scan manually or use Autoscan

### Permission Issues

```bash
# Fix permissions
sudo chown -R 1000:1000 /mediacenter
sudo chmod -R 775 /mediacenter
```

## 🎯 Post-Installation

1. **Configure Autoscan** - Automatically scan new content in Plex
2. **Set up Petio** - Request management system
3. **Configure quality profiles** in Radarr/Sonarr
4. **Add custom formats** for better release selection
5. **Set up notifications** in *arr apps

## 📚 Additional Resources

- [Sailarr Guide](https://savvyguides.wiki/sailarrsguide/)
- [Zurg Documentation](https://github.com/debridmediamanager/zurg-testing)
- [Blackhole Scripts](https://github.com/westsurname/scripts)
- [TRaSH Guides](https://trash-guides.info/) - Quality profiles and custom formats

## ⚠️ Important Notes

- **All containers must use the same PUID/PGID** for symlinks to work
- **The `/mnt` volume mapping** is critical - it must be consistent across all containers
- **Real-Debrid API limits** - Don't hammer the API, Zurg handles rate limiting
- **Cached torrents only** - Blackhole only works with cached content by default

## Helper Scripts

A collection of maintenance scripts (based on Pukabyte's Real-Debrid-Scripts) is available in the `scripts/` directory.

- **`discard.py`**: Removes torrents from Real-Debrid that are not used in your Plex library.
- **`brokensymlinks.py`**: Finds and removes broken symlinks.
- **`symclean.py`**: Rewrites symlinks if you change mount paths.
- **`zurgupdate.sh`**: Updates Zurg and restarts services.

See `scripts/README.md` for usage instructions.

## Maintenance** - Clean up old symlinks and check Real-Debrid storage

## 📝 License

This setup is based on the community Sailarr guide and uses various open-source projects. Please respect their individual licenses.
