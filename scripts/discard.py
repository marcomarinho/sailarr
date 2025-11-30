import os
import argparse
import shutil
import traceback

def find_non_linked_files(src_folder, dst_folder, dry_run=False, no_confirm=False):
    # Get the list of links in the dst_folder
    dst_links = set()
    for root, dirs, files in os.walk(dst_folder):
        for file in files:
            dst_path = os.path.join(root, file)
            if os.path.islink(dst_path):
                # We need to read the link target directly because realpath might resolve to a path that doesn't exist on host
                # or might be different if running on host vs container.
                # However, the original script used realpath.
                # If symlinks are absolute "/data/remote/...", realpath returns that.
                # If we scan src_folder which is "/mediacenter/data/remote/...", they won't match.
                # So we should probably normalize or just use the target string if it's absolute.
                
                try:
                    target = os.readlink(dst_path)
                    # If target is absolute, use it. If relative, resolve it relative to dst_path.
                    if not os.path.isabs(target):
                        target = os.path.normpath(os.path.join(os.path.dirname(dst_path), target))
                    dst_links.add(target)
                except OSError:
                    continue

    # Check for non-linked files in the src_folder
    for root, dirs, files in os.walk(src_folder):
        # Get the subdirectory of the current root, relative to the src_folder
        subdirectory = os.path.relpath(root, src_folder)
        subdirectory_any_linked_files = False
        for file in files:
            # We need to construct the path as it would appear in the symlink target
            # If src_folder is /mediacenter/data/remote/realdebrid
            # and symlink points to /data/remote/realdebrid
            # we need to map.
            
            # For now, let's assume the user configures src_folder to match the symlink targets
            # OR we rely on the user to run this inside a container with correct mounts.
            
            src_file = os.path.join(root, file)
            
            # If we are running on host, src_file might be /mediacenter/data/remote/...
            # but symlink target is /data/remote/...
            # We can try to handle this by checking if src_file ends with the symlink target
            
            if src_file in dst_links:
                subdirectory_any_linked_files = True
            else:
                # Try to match by suffix if paths differ (host vs container)
                # This is a heuristic.
                for link in dst_links:
                    if src_file.endswith(link) or link.endswith(src_file):
                        subdirectory_any_linked_files = True
                        break
        
        if any(files) and not subdirectory_any_linked_files:
            print(f"Directory {subdirectory} is not used!")
            if not dry_run:
                response = input("Do you want to delete this directory? (y/n): ") if not no_confirm else 'y'
                if response.lower() == 'y':
                    try:
                        for root, dirs, files in os.walk(root):
                            for f in files:
                               os.unlink(os.path.join(root, f))
                            for d in dirs:
                                shutil.rmtree(os.path.join(root, d))
                        print(f"Directory {subdirectory} deleted!")
                    except Exception as e:
                        print(f"Directory {subdirectory} error during deletion!")
                        print(traceback.format_exc())
                else:
                    print(f"Directory {subdirectory} not deleted!")

if __name__ == '__main__':
    # Defaults updated for Sailarr setup
    # NOTE: These paths assume you are running inside a container with /data mapped,
    # OR you have adjusted them to match your host paths.
    src_folder = "/data/remote/realdebrid" # Location of your debrid mount
    dst_folder = "/data/plex" # Location of your media directory
    
    parser = argparse.ArgumentParser(description='Find and delete non-linked file directories.')
    parser.add_argument('--src', default=src_folder, help='Source folder (Real-Debrid mount)')
    parser.add_argument('--dst', default=dst_folder, help='Destination folder (Plex media)')
    parser.add_argument('--dry-run', action='store_true', help='print non-linked file directories without deleting')
    parser.add_argument('--no-confirm', action='store_true', help='delete non-linked file directories without confirmation')
    args = parser.parse_args()
    
    print(f"Scanning source: {args.src}")
    print(f"Scanning destination: {args.dst}")
    
    find_non_linked_files(args.src, args.dst, dry_run=args.dry_run, no_confirm=args.no_confirm)
