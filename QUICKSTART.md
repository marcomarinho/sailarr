# Quick Start Guide

Get your Sailarr media center up and running in minutes!

## Prerequisites Checklist

- [ ] Linux server (Ubuntu 22.04+ recommended)
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] Real-Debrid account with active subscription
- [ ] Real-Debrid API token from https://real-debrid.com/apitoken
- [ ] Your PUID and PGID (run `id` command)

## Installation Steps

### Step 1: Clone or Download

```bash
cd ~
git clone <your-repo-url> sailarr
cd sailarr
```

Or if you downloaded manually:

```bash
cd /path/to/sailarr
```

### Step 2: Make Scripts Executable

```bash
chmod +x setup.sh manage.sh
```

### Step 3: Run Setup Script

```bash
sudo ./setup.sh
```

This will create the directory structure in `/mediacenter/`

### Step 4: Configure Environment

```bash
cp .env.example .env
nano .env
```

**Required changes:**
- Set `PUID` and `PGID` (from `id` command)
- Set `TZ` (your timezone)
- Set `REALDEBRID_API_KEY` (from Real-Debrid)

Save and exit (Ctrl+X, Y, Enter)

### Step 5: Configure Zurg

```bash
nano /mediacenter/configs/zurg/config.yml
```

Find this line:
```yaml
token: ENTER_YOUR_REALDEBRID_API_TOKEN_HERE
```

Replace with your Real-Debrid API token.

Save and exit (Ctrl+X, Y, Enter)

### Step 6: Copy Files to /mediacenter

```bash
# Copy docker-compose.yml
sudo cp docker-compose.yml /mediacenter/

# Copy .env
sudo cp .env /mediacenter/

# Copy management script
sudo cp manage.sh /mediacenter/
sudo chmod +x /mediacenter/manage.sh

# Copy scripts
sudo cp -r scripts /mediacenter/
sudo chmod +x /mediacenter/scripts/*.sh

# Change to mediacenter directory
cd /mediacenter
```

### Step 7: Start Core Services

```bash
./manage.sh core
```

Wait 30 seconds for Zurg to start and become healthy.

### Step 8: Verify Mount

```bash
./manage.sh verify-mount
```

You should see your Real-Debrid content listed.

### Step 9: Start All Services

```bash
./manage.sh start
```

### Step 10: Access Services

```bash
./manage.sh urls
```

This will show you all the service URLs.

## Initial Configuration

### 1. Plex (http://YOUR_IP:32400/web)

1. Sign in with your Plex account
2. Name your server
3. Add libraries:
   - Movies: `/data/plex/Movies`
   - TV: `/data/plex/TV`

### 2. Prowlarr (http://YOUR_IP:9696)

1. Set up authentication
2. Copy API key
3. Add indexers (YTS, EZTV, 1337x, etc.)

### 3. Radarr (http://YOUR_IP:7878)

1. Set up authentication
2. Copy API key → Add to `.env` as `RADARR_API_KEY`
3. Add root folder: `/data/plex/Movies`
4. Add download client:
   - Type: Torrent Blackhole
   - Torrent Folder: `/data/symlinks/radarr/processing`
   - Watch Folder: `/data/symlinks/radarr/completed`
   - Save Magnet Files: Yes
   - Magnet Extension: `.magnet`

### 4. Sonarr (http://YOUR_IP:8989)

1. Set up authentication
2. Copy API key → Add to `.env` as `SONARR_API_KEY`
3. Add root folder: `/data/plex/TV`
4. Add download client:
   - Type: Torrent Blackhole
   - Torrent Folder: `/data/symlinks/sonarr/processing`
   - Watch Folder: `/data/symlinks/sonarr/completed`
   - Save Magnet Files: Yes
   - Magnet Extension: `.magnet`

### 5. Update .env and Restart Blackhole

After adding all API keys to `.env`:

```bash
nano .env
# Add all the API keys you copied

# Restart blackhole
docker-compose restart blackhole
```

### 8. Connect Prowlarr to *arr Apps

In Prowlarr:
- Settings > Apps > Add Application
- Add each Radarr and Sonarr instance with their API keys

## Test Your Setup

### Test Movie Download

1. Go to Radarr
2. Add a popular movie (e.g., "The Matrix")
3. Search for it
4. Select a release
5. Monitor: `docker-compose logs -f blackhole`
6. Check Plex after a few minutes

### Test TV Show Download

1. Go to Sonarr
2. Add a popular show (e.g., "Breaking Bad")
3. Search for S01E01
4. Select a release
5. Monitor: `docker-compose logs -f blackhole`
6. Check Plex after a few minutes

## Common Issues

### Mount not working

```bash
# Check Zurg logs
docker-compose logs zurg

# Check rclone logs
docker-compose logs rclone

# Restart core services
./manage.sh core
```

### Blackhole not creating symlinks

```bash
# Check blackhole logs
docker-compose logs blackhole

# Verify API keys in .env
cat .env | grep API_KEY

# Restart blackhole
docker-compose restart blackhole
```

### Plex not seeing files

```bash
# Verify mount
./manage.sh verify-mount

# Check symlinks
ls -la /mediacenter/data/plex/Movies/

# Manually scan library in Plex
```

### Permission errors

```bash
# Fix permissions
sudo chown -R $(id -u):$(id -g) /mediacenter
sudo chmod -R 775 /mediacenter

# Restart all services
./manage.sh restart
```

## Useful Commands

```bash
# View all service URLs
./manage.sh urls

# Check status
./manage.sh status

# View logs
./manage.sh logs [service]

# Restart all
./manage.sh restart

# Stop all
./manage.sh stop

# Start all
./manage.sh start

# Verify mount
./manage.sh verify-mount

# Clean broken symlinks
./manage.sh cleanup

# Update all services
./manage.sh update
```

## Next Steps

1. Read [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration
2. Set up quality profiles using [TRaSH Guides](https://trash-guides.info/)
3. Configure Autoscan for instant library updates
4. Set up Overseerr for user requests
5. Configure notifications in *arr apps

## Getting Help

- Check logs: `./manage.sh logs [service]`
- Read [CONFIGURATION.md](CONFIGURATION.md)
- Read [DIRECTORY_STRUCTURE.md](DIRECTORY_STRUCTURE.md)
- Visit [Sailarr Guide](https://savvyguides.wiki/sailarrsguide/)
- Check [Zurg Documentation](https://github.com/debridmediamanager/zurg-testing)

## Maintenance

### Weekly

- Check Real-Debrid storage
- Clean up broken symlinks: `./manage.sh cleanup`

### Monthly

- Update services: `./manage.sh update`
- Review and clean up old content
- Check logs for errors

### As Needed

- Backup configs: `tar -czf configs-backup.tar.gz /mediacenter/configs/`
- Monitor disk usage: `df -h`
- Check Docker resources: `docker system df`

---

**Congratulations!** 🎉 Your Sailarr media center is now running!

Enjoy your automated media server with Real-Debrid integration!
