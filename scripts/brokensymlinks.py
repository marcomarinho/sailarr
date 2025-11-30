import os
import argparse

def find_broken_symlinks(directory, dry_run=False):
    broken_symlinks = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            path = os.path.join(root, file)
            if os.path.islink(path):
                try:
                    target = os.readlink(path)
                    # Check if target exists
                    # Note: If target is absolute path inside container (e.g. /data/remote/...),
                    # and we run this on host, it might report broken even if valid in container.
                    # Ideally run this inside the container.
                    if not os.path.exists(target):
                        broken_symlinks.append(path)
                        if not dry_run:
                            os.unlink(path)
                except OSError:
                    continue
    return broken_symlinks

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Find and remove broken symlinks.")
    parser.add_argument("--dir", default="/data/plex", help="Directory to scan")
    parser.add_argument("--dry-run", action="store_true", help="Print broken symlinks without deleting")
    parser.add_argument("--force", action="store_true", help="Actually delete (default is dry-run unless --force is used)")
    
    args = parser.parse_args()
    
    # Default to dry-run if --force is not specified, unless --dry-run is explicitly passed (which is redundant but clear)
    # Actually, let's make it safe: default is dry-run. --force enables deletion.
    dry_run = not args.force
    
    print(f"Scanning {args.dir} for broken symlinks...")
    if dry_run:
        print("DRY RUN: No files will be deleted. Use --force to delete.")
    
    broken_symlinks = find_broken_symlinks(args.dir, dry_run)

    if dry_run:
        print(f"Found {len(broken_symlinks)} broken symlinks:")
        for symlink in broken_symlinks:
            print(symlink)
    else:
        print(f"Removed {len(broken_symlinks)} broken symlinks.")
