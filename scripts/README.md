# Sailarr Scripts

This directory contains helper scripts for maintaining your Sailarr media center.
Based on [Real-Debrid-Scripts by Pukabyte](https://github.com/Pukabyte/Real-Debrid-Scripts).

## Scripts

### 1. `discard.py`
Removes torrents from Real-Debrid that do not have a corresponding symlink in your Plex library. This helps clean up your Real-Debrid cloud.

**Usage:**
```bash
# Run inside the blackhole container (recommended for path compatibility)
docker-compose run --rm blackhole python3 /scripts/discard.py --dry-run

# Or run on host (requires python3)
python3 scripts/discard.py --src /mediacenter/data/remote/realdebrid --dst /mediacenter/data/plex --dry-run
```

### 2. `brokensymlinks.py`
Finds and removes broken symlinks in your library. Useful if you deleted files from Real-Debrid but symlinks remain.

**Usage:**
```bash
# Run inside blackhole container
docker-compose run --rm blackhole python3 /scripts/brokensymlinks.py --dry-run

# Or on host
python3 scripts/brokensymlinks.py --dir /mediacenter/data/plex --dry-run
```
Use `--force` to actually delete files.

### 3. `symclean.py`
Rewrites symlinks if you changed your mount path.

**Usage:**
```bash
python3 scripts/symclean.py
```
Follow the interactive prompts.

### 4. `zurgupdate.sh`
Updates Zurg and restarts all dependent services in the correct order.

**Usage:**
```bash
chmod +x scripts/zurgupdate.sh
./scripts/zurgupdate.sh
```

## Note on Paths
The Python scripts assume paths match your container configuration (`/data/remote/realdebrid` and `/data/plex`). If running on the host, ensure you pass the correct host paths using arguments.
