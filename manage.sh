#!/bin/bash

# Sailarr Media Center - Management Script
# Provides easy commands to manage the media center stack

set -e

COMPOSE_FILE="docker-compose.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if docker-compose exists
check_compose() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        print_error "docker-compose.yml not found!"
        exit 1
    fi
}

# Start all services
start_all() {
    print_header "Starting All Services"
    check_compose
    docker-compose up -d
    print_success "All services started!"
    show_status
}

# Stop all services
stop_all() {
    print_header "Stopping All Services"
    check_compose
    docker-compose down
    print_success "All services stopped!"
}

# Restart all services
restart_all() {
    print_header "Restarting All Services"
    check_compose
    docker-compose restart
    print_success "All services restarted!"
}

# Start core services (Zurg + rclone)
start_core() {
    print_header "Starting Core Services (Zurg + rclone)"
    check_compose
    docker-compose up -d zurg rclone
    print_success "Core services started!"
    print_info "Waiting for Zurg to be healthy..."
    sleep 5
    show_status
}

# Show status of all services
show_status() {
    print_header "Service Status"
    check_compose
    docker-compose ps
}

# Show logs
show_logs() {
    check_compose
    if [ -z "$1" ]; then
        print_info "Showing logs for all services (Ctrl+C to exit)"
        docker-compose logs -f
    else
        print_info "Showing logs for $1 (Ctrl+C to exit)"
        docker-compose logs -f "$1"
    fi
}

# Update all services
update_all() {
    print_header "Updating All Services"
    check_compose
    print_info "Pulling latest images..."
    docker-compose pull
    print_info "Recreating containers..."
    docker-compose up -d
    print_success "All services updated!"
}

# Verify mount
verify_mount() {
    print_header "Verifying Real-Debrid Mount"
    
    MOUNT_PATH="./data/remote/realdebrid"
    
    if [ ! -d "$MOUNT_PATH" ]; then
        print_error "Mount directory does not exist: $MOUNT_PATH"
        exit 1
    fi
    
    print_info "Checking mount at: $MOUNT_PATH"
    
    if mountpoint -q "$MOUNT_PATH" 2>/dev/null; then
        print_success "Mount is active!"
        print_info "Contents:"
        ls -lah "$MOUNT_PATH" | head -20
    else
        # Check if there are files (might be bind mount)
        if [ "$(ls -A $MOUNT_PATH 2>/dev/null)" ]; then
            print_success "Mount appears to be working!"
            print_info "Contents:"
            ls -lah "$MOUNT_PATH" | head -20
        else
            print_error "Mount appears to be empty or not working!"
            print_info "Check Zurg and rclone logs:"
            echo "  docker-compose logs zurg"
            echo "  docker-compose logs rclone"
        fi
    fi
}

# Show service URLs
show_urls() {
    print_header "Service URLs"
    
    # Get host IP
    HOST_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo -e "${GREEN}Plex:${NC}        http://${HOST_IP}:32400/web"
    echo -e "${GREEN}Radarr:${NC}      http://${HOST_IP}:7878"
    echo -e "${GREEN}Sonarr:${NC}      http://${HOST_IP}:8989"
    echo -e "${GREEN}Prowlarr:${NC}    http://${HOST_IP}:9696"
    echo -e "${GREEN}Autoscan:${NC}    http://${HOST_IP}:3030"
    echo -e "${GREEN}Overseerr:${NC}   http://${HOST_IP}:5055"
    echo -e "${GREEN}Zurg:${NC}        http://${HOST_IP}:9999"
    echo ""
}

# Clean up old symlinks
cleanup_symlinks() {
    print_header "Cleaning Up Symlinks"
    
    print_warning "This will remove broken symlinks from the Plex directories"
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Finding broken symlinks..."
        find ./data/plex -xtype l -delete
        print_success "Cleanup complete!"
    else
        print_info "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    cat << EOF
Sailarr Media Center Management Script

Usage: ./manage.sh [command] [options]

Commands:
    start           Start all services
    stop            Stop all services
    restart         Restart all services
    core            Start core services only (Zurg + rclone)
    status          Show status of all services
    logs [service]  Show logs (all services or specific service)
    update          Update all services to latest versions
    verify-mount    Verify Real-Debrid mount is working
    urls            Show URLs for all web interfaces
    cleanup         Clean up broken symlinks
    help            Show this help message

Examples:
    ./manage.sh start              # Start all services
    ./manage.sh logs plex          # Show Plex logs
    ./manage.sh logs               # Show all logs
    ./manage.sh verify-mount       # Check if mount is working
    ./manage.sh cleanup            # Remove broken symlinks

EOF
}

# Main script
case "${1:-help}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    core)
        start_core
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    update)
        update_all
        ;;
    verify-mount|verify)
        verify_mount
        ;;
    urls)
        show_urls
        ;;
    cleanup)
        cleanup_symlinks
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
