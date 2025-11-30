# Sailarr Configuration Guide

This guide will walk you through configuring each service in your Sailarr media center.

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Zurg Configuration](#zurg-configuration)
3. [Plex Configuration](#plex-configuration)
4. [Prowlarr Configuration](#prowlarr-configuration)
5. [Radarr Configuration](#radarr-configuration)
6. [Sonarr Configuration](#sonarr-configuration)
7. [Blackhole Configuration](#blackhole-configuration)
8. [Autoscan Configuration](#autoscan-configuration)
9. [Overseerr Configuration](#overseerr-configuration)
10. [Recyclarr Configuration](#recyclarr-configuration)

---

## Initial Setup

### 1. Environment Variables

Copy the example environment file and edit it:

```bash
cp .env.example .env
nano .env
```

**Required settings:**

- `PUID` and `PGID` - Run `id` command to get your user/group IDs
- `TZ` - Your timezone (e.g., `America/New_York`, `Europe/London`)
- `REALDEBRID_API_KEY` - Get from https://real-debrid.com/apitoken

**Optional settings:**

- `PLEX_CLAIM` - Get from https://www.plex.tv/claim/ (only needed for initial Plex setup)

### 2. Start Core Services

Start Zurg and rclone first:

```bash
./manage.sh core
```

Wait for Zurg to be healthy (check with `./manage.sh status`), then start all services:

```bash
./manage.sh start
```

---

## Zurg Configuration

Zurg is already configured in `configs/zurg/config.yml`. You only need to add your Real-Debrid API token.

### Edit Zurg Config

```bash
nano configs/zurg/config.yml
```

Find this line and replace with your token:

```yaml
token: ENTER_YOUR_REALDEBRID_API_TOKEN_HERE
```

### Verify Zurg is Working

```bash
# Check Zurg logs
docker-compose logs zurg

# Check if mount is working
./manage.sh verify-mount
```

You should see your Real-Debrid content in `data/remote/realdebrid/`

---

## Plex Configuration

### 1. Initial Setup

Access Plex at: `http://YOUR_SERVER_IP:32400/web`

1. Sign in with your Plex account
2. Give your server a name
3. Skip the library setup for now

### 2. Add Libraries

Add the following libraries:

**Movies Library:**
- Type: Movies
- Folder: `/data/plex/Movies`
- Scanner: Plex Movie Scanner
- Agent: Plex Movie

**TV Shows Library:**
- Type: TV Shows
- Folder: `/data/plex/TV`
- Scanner: Plex Series Scanner
- Agent: Plex Series

### 3. Get Plex Information for Blackhole

You'll need these for the blackhole configuration:

1. **Server Machine ID**: Settings > General > scroll down
2. **API Token**: 
   - Go to any library
   - Click on a movie/show
   - Click the three dots > "Get Info"
   - Click "View XML"
   - Look at the URL, find `X-Plex-Token=...`

---

## Prowlarr Configuration

Access Prowlarr at: `http://YOUR_SERVER_IP:9696`

### 1. Initial Setup

1. Set up authentication (Settings > General > Authentication)
2. Copy the API key (Settings > General > API Key)

### 2. Add Indexers

Go to Indexers > Add Indexer

**Recommended public indexers:**
- YTS
- EZTV
- The Pirate Bay
- 1337x
- RARBG

> **Note:** With Real-Debrid, you only need public indexers since you're not actually torrenting.

### 3. Connect to Radarr/Sonarr

Go to Settings > Apps > Add Application

**For Radarr:**
- Name: Radarr
- Sync Level: Full Sync
- Prowlarr Server: http://prowlarr:9696
- Radarr Server: http://radarr:7878
- API Key: (get from Radarr - see below)

**For Sonarr:**
- Name: Sonarr
- Sync Level: Full Sync
- Prowlarr Server: http://prowlarr:9696
- Sonarr Server: http://sonarr:8989
- API Key: (get from Sonarr)

---

## Radarr Configuration

Access Radarr at: `http://YOUR_SERVER_IP:7878`

### 1. Initial Setup

1. Set up authentication (Settings > General > Authentication)
2. Copy the API key (Settings > General > API Key)
3. Add this to your `.env` file as `RADARR_API_KEY`

### 2. Add Root Folder

Settings > Media Management > Root Folders > Add Root Folder

- **Radarr**: `/data/plex/Movies`

### 3. Configure Download Client (Blackhole)

Settings > Download Clients > Add > Torrent Blackhole

**For Radarr:**
- Name: `Blackhole`
- Enable: Yes
- Torrent Folder: `/data/symlinks/radarr/processing`
- Watch Folder: `/data/symlinks/radarr/completed`
- Save Magnet Files: Yes
- Magnet File Extension: `.magnet`
- Read Only: No

### 4. Quality Profiles

Settings > Profiles

Create or modify quality profiles based on your preferences.

### 5. Media Management Settings

Settings > Media Management

- **Rename Movies**: Yes
- **Replace Illegal Characters**: Yes
- **Standard Movie Format**: 
  ```
  {Movie Title} ({Release Year}) {Quality Full}
  ```
- **Movie Folder Format**:
  ```
  {Movie Title} ({Release Year})
  ```

---

## Sonarr Configuration

Access Sonarr at: `http://YOUR_SERVER_IP:8989`

### 1. Initial Setup

1. Set up authentication (Settings > General > Authentication)
2. Copy the API key (Settings > General > API Key)
3. Add this to your `.env` file as `SONARR_API_KEY`

### 2. Add Root Folder

Settings > Media Management > Root Folders > Add Root Folder

- **Sonarr**: `/data/plex/TV`

### 3. Configure Download Client (Blackhole)

Settings > Download Clients > Add > Torrent Blackhole

**For Sonarr:**
- Name: `Blackhole`
- Enable: Yes
- Torrent Folder: `/data/symlinks/sonarr/processing`
- Watch Folder: `/data/symlinks/sonarr/completed`
- Save Magnet Files: Yes
- Magnet File Extension: `.magnet`
- Read Only: No

### 4. Quality Profiles

Settings > Profiles

Create or modify quality profiles based on your preferences.

### 5. Media Management Settings

Settings > Media Management

- **Rename Episodes**: Yes
- **Replace Illegal Characters**: Yes
- **Standard Episode Format**:
  ```
  {Series Title} - S{season:00}E{episode:00} - {Episode Title} {Quality Full}
  ```
- **Season Folder Format**:
  ```
  Season {season:00}
  ```
- **Series Folder Format**:
  ```
  {Series Title} ({Series Year})
  ```

---

## Blackhole Configuration

The blackhole service is configured via environment variables in the `.env` file.

### Update .env File

After setting up Radarr and Sonarr, update your `.env` file with the API keys:

```bash
nano .env
```

Add the API keys you copied from each service:

```env
RADARR_API_KEY=your_radarr_api_key_here
SONARR_API_KEY=your_sonarr_api_key_here
```

### Restart Blackhole

```bash
docker-compose restart blackhole
```

### Monitor Blackhole

```bash
# Watch blackhole logs
docker-compose logs -f blackhole

# Check blackhole log files
tail -f configs/blackhole/logs/*.log
```

---

## Autoscan Configuration

Autoscan automatically triggers Plex library scans when new content is added.

Access Autoscan at: `http://YOUR_SERVER_IP:3030`

### 1. Initial Configuration

Create the config file:

```bash
nano configs/autoscan/config.yml
```

Basic configuration:

```yaml
# Autoscan configuration
port: 3030

# Plex configuration
plex:
  - url: http://plex:32400
    token: YOUR_PLEX_TOKEN_HERE

# Triggers
triggers:
  radarr:
    - name: radarr
      priority: 2

  sonarr:
    - name: sonarr
      priority: 2

# Targets
targets:
  plex:
    - url: http://plex:32400
      token: YOUR_PLEX_TOKEN_HERE
```

### 2. Configure in Radarr/Sonarr

In each *arr app:

Settings > Connect > Add > Webhook

- Name: `Autoscan`
- On Grab: No
- On Import: Yes
- On Upgrade: Yes
- On Rename: Yes

### 1. Configuration File

The configuration file is located at `configs/recyclarr/recyclarr.yml`. It has been pre-configured with recommended settings for:
- **Radarr**: 1080p and 4K profiles with custom formats
- **Sonarr**: 1080p and 4K profiles with custom formats

### 2. API Keys

You need to add your Radarr and Sonarr API keys to the `recyclarr.yml` file.

```bash
nano configs/recyclarr/recyclarr.yml
```

Find the `api_key` fields under `radarr` and `sonarr` sections and add your keys:

```yaml
radarr:
  movies:
    base_url: http://radarr:7878
    api_key: YOUR_RADARR_API_KEY

sonarr:
  series:
    base_url: http://sonarr:8989
    api_key: YOUR_SONARR_API_KEY
```

### 3. Syncing

Recyclarr runs on a schedule, but you can force a sync manually:

```bash
docker-compose run --rm recyclarr sync
```

This will create the quality profiles (e.g., `Recyclarr-1080p`, `Recyclarr-2160p`) in your *arr apps.

### 4. Assign Profiles

After syncing, go to your *arr apps and assign the new profiles to your media:
- **Radarr**: Settings > Profiles (verify they exist)
- **Sonarr**: Settings > Profiles (verify they exist)

You can then use these profiles when adding new content.

---

## Testing the Setup

### 1. Test a Movie Download

1. Go to Radarr
2. Add a popular movie
3. Search for it
4. Select a release
5. Monitor the blackhole logs: `docker-compose logs -f blackhole`
6. Check if symlink is created: `ls -la data/plex/Movies/`
7. Verify in Plex

### 2. Test a TV Show Download

1. Go to Sonarr
2. Add a popular TV show
3. Search for an episode
4. Select a release
5. Monitor the blackhole logs
6. Check if symlink is created: `ls -la data/plex/TV/`
7. Verify in Plex

---

## Troubleshooting

### Blackhole not working

1. Check logs: `docker-compose logs blackhole`
2. Verify Real-Debrid API key in `.env`
3. Verify *arr API keys in `.env`
4. Check if mount is working: `./manage.sh verify-mount`

### Symlinks not appearing

1. Verify PUID/PGID is the same across all services
2. Check permissions: `ls -la data/symlinks/`
3. Verify torrent is cached on Real-Debrid
4. Check blackhole logs for errors

### Plex not scanning

1. Manually trigger scan in Plex
2. Set up Autoscan
3. Check Plex logs: `docker-compose logs plex`
4. Verify library paths are correct

---

## Next Steps

1. **Set up quality profiles** in Radarr/Sonarr using [TRaSH Guides](https://trash-guides.info/)
2. **Configure custom formats** for better release selection
3. **Set up notifications** (Discord, Telegram, etc.)
4. **Configure Autoscan** for instant library updates
5. **Explore Overseerr** for user requests
6. **Regular maintenance** - clean up old symlinks and check Real-Debrid storage

---

## Useful Commands

```bash
# Start all services
./manage.sh start

# Stop all services
./manage.sh stop

# View logs
./manage.sh logs [service_name]

# Check status
./manage.sh status

# Verify mount
./manage.sh verify-mount

# Show all URLs
./manage.sh urls

# Clean up broken symlinks
./manage.sh cleanup

# Update all services
./manage.sh update
```
