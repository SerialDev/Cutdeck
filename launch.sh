#!/bin/bash

set -e

TUNNEL_NAME="cutdeck"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                        ${GREEN}CUTDECK${NC}                              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     React 19 + TypeScript + Vite + FastAPI + DaggyD       ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

usage() {
    print_header
    echo -e "${YELLOW}Usage:${NC} ./launch.sh <command> [options]"
    echo ""
    echo -e "${GREEN}Development Commands:${NC}"
    echo "  dev             Start frontend + backend for local development"
    echo "  dev -d          Start in detached mode"
    echo "  frontend        Start only the frontend (React + Vite)"
    echo "  backend         Start only the backend (FastAPI + DaggyD)"
    echo ""
    echo -e "${GREEN}Production Commands:${NC}"
    echo "  prod            Start production build (nginx + backend)"
    echo "  prod -d         Start production in detached mode"
    echo ""
    echo -e "${GREEN}Cloudflare Tunnel Commands:${NC}"
    echo "  setup           Authenticate and create cloudflared tunnel"
    echo "  tunnel          Start all services WITH cloudflare tunnel"
    echo "  tunnel -d       Start tunnel services in detached mode"
    echo ""
    echo -e "${CYAN}Cloudflare Containers Commands (Edge Deployment):${NC}"
    echo "  cf:deploy       Deploy backend to Cloudflare Containers"
    echo "  cf:dev          Run Workers in local development mode"
    echo "  cf:status       Show container deployment status"
    echo "  cf:logs         View container logs"
    echo "  cf:setup        Setup Cloudflare resources (D1, KV)"
    echo ""
    echo -e "${GREEN}Management Commands:${NC}"
    echo "  stop            Stop all running services"
    echo "  logs [service]  View logs (optionally for specific service)"
    echo "  status          Show status of all services"
    echo "  build           Build all Docker images"
    echo "  clean           Remove all containers, images, and volumes"
    echo ""
    echo -e "${GREEN}Service Names:${NC}"
    echo "  frontend, backend, cloudflared, frontend-prod"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  ./launch.sh dev              # Start development environment"
    echo "  ./launch.sh setup            # Setup cloudflare tunnel"
    echo "  ./launch.sh tunnel -d        # Start with tunnel in background"
    echo "  ./launch.sh cf:deploy        # Deploy to Cloudflare Containers"
    echo "  ./launch.sh logs backend     # View backend logs only"
    echo ""
}

# =============================================================================
# SETUP - Cloudflare Tunnel Authentication
# =============================================================================
setup_tunnel() {
    print_header
    echo -e "${YELLOW}==> Step 1/3: Authenticating with Cloudflare...${NC}"
    echo "    This will open a browser window for authentication."
    echo ""
    
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}Error: cloudflared is not installed.${NC}"
        echo "Install it from: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/"
        exit 1
    fi
    
    cloudflared tunnel login
    
    echo ""
    echo -e "${YELLOW}==> Step 2/3: Creating tunnel '$TUNNEL_NAME'...${NC}"
    
    # Check if tunnel already exists
    if cloudflared tunnel list | grep -q "$TUNNEL_NAME"; then
        echo -e "${YELLOW}    Tunnel '$TUNNEL_NAME' already exists.${NC}"
        TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    else
        cloudflared tunnel create "$TUNNEL_NAME"
        TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    fi
    
    echo ""
    echo -e "${GREEN}==> Step 3/3: Tunnel created successfully!${NC}"
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                    ${GREEN}TUNNEL INFORMATION${NC}                       ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}  Tunnel Name: ${GREEN}$TUNNEL_NAME${NC}"
    echo -e "${BLUE}║${NC}  Tunnel ID:   ${GREEN}$TUNNEL_ID${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo ""
    echo "  1. Edit ${GREEN}cloudflared/config.yml${NC}:"
    echo "     - Replace ${RED}<TUNNEL_ID>${NC} with: ${GREEN}$TUNNEL_ID${NC}"
    echo "     - Replace ${RED}<YOUR_DOMAIN>${NC} with your domain"
    echo ""
    echo "  2. Create DNS records in Cloudflare dashboard:"
    echo "     ${BLUE}cloudflared tunnel route dns $TUNNEL_NAME yourdomain.com${NC}"
    echo "     ${BLUE}cloudflared tunnel route dns $TUNNEL_NAME api.yourdomain.com${NC}"
    echo ""
    echo "  3. Start services with tunnel:"
    echo "     ${GREEN}./launch.sh tunnel${NC}"
    echo ""
}

# =============================================================================
# DEVELOPMENT - Local development with hot reload
# =============================================================================
run_dev() {
    print_header
    echo -e "${GREEN}==> Starting development environment...${NC}"
    echo "    Frontend: http://localhost:3000"
    echo "    Backend:  http://localhost:8000"
    echo "    API Docs: http://localhost:8000/docs"
    echo ""
    
    if [ "$1" == "-d" ]; then
        docker-compose up -d frontend backend
        echo ""
        echo -e "${GREEN}==> Services started in detached mode${NC}"
        echo "    Use '${YELLOW}./launch.sh logs${NC}' to view logs"
        echo "    Use '${YELLOW}./launch.sh status${NC}' to check status"
    else
        docker-compose up frontend backend
    fi
}

run_frontend() {
    print_header
    echo -e "${GREEN}==> Starting frontend only...${NC}"
    echo "    Frontend: http://localhost:3000"
    echo ""
    docker-compose up frontend
}

run_backend() {
    print_header
    echo -e "${GREEN}==> Starting backend only...${NC}"
    echo "    Backend:  http://localhost:8000"
    echo "    API Docs: http://localhost:8000/docs"
    echo ""
    docker-compose up backend
}

# =============================================================================
# PRODUCTION - Production build with nginx
# =============================================================================
run_prod() {
    print_header
    echo -e "${GREEN}==> Starting production environment...${NC}"
    echo "    Frontend: http://localhost:80"
    echo "    Backend:  http://localhost:8000"
    echo ""
    
    if [ "$1" == "-d" ]; then
        docker-compose --profile production up -d frontend-prod backend
        echo ""
        echo -e "${GREEN}==> Production services started in detached mode${NC}"
    else
        docker-compose --profile production up frontend-prod backend
    fi
}

# =============================================================================
# TUNNEL - Run with Cloudflare Tunnel
# =============================================================================
run_tunnel() {
    print_header
    echo -e "${GREEN}==> Starting services with Cloudflare Tunnel...${NC}"
    echo "    Frontend: http://localhost:3000 (and via tunnel)"
    echo "    Backend:  http://localhost:8000 (and via tunnel)"
    echo ""
    
    # Check if config has been updated
    if grep -q "<TUNNEL_ID>" "$PROJECT_ROOT/cloudflared/config.yml"; then
        echo -e "${RED}Error: cloudflared/config.yml has not been configured.${NC}"
        echo "Please run '${GREEN}./launch.sh setup${NC}' first, then update the config file."
        exit 1
    fi
    
    if [ "$1" == "-d" ]; then
        docker-compose --profile tunnel up -d
        echo ""
        echo -e "${GREEN}==> All services started with tunnel in detached mode${NC}"
    else
        docker-compose --profile tunnel up
    fi
}

# =============================================================================
# CLOUDFLARE CONTAINERS - Edge Deployment
# =============================================================================
cf_deploy() {
    print_header
    echo -e "${CYAN}==> Deploying to Cloudflare Containers...${NC}"
    echo "    This will build and push your container to Cloudflare's edge network."
    echo ""
    
    cd "$PROJECT_ROOT/workers"
    
    # Check if node_modules exists
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}==> Installing dependencies...${NC}"
        npm install
    fi
    
    echo -e "${YELLOW}==> Building and deploying...${NC}"
    echo "    Note: First deploy may take several minutes."
    echo ""
    
    npx wrangler deploy
    
    echo ""
    echo -e "${GREEN}==> Deployment complete!${NC}"
    echo ""
    echo -e "${YELLOW}Check status with:${NC} ./launch.sh cf:status"
    echo -e "${YELLOW}View logs with:${NC} ./launch.sh cf:logs"
}

cf_dev() {
    print_header
    echo -e "${CYAN}==> Starting Cloudflare Workers development server...${NC}"
    echo ""
    
    cd "$PROJECT_ROOT/workers"
    
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}==> Installing dependencies...${NC}"
        npm install
    fi
    
    npx wrangler dev
}

cf_status() {
    print_header
    echo -e "${CYAN}==> Cloudflare Containers Status${NC}"
    echo ""
    
    cd "$PROJECT_ROOT/workers"
    
    echo -e "${YELLOW}Containers:${NC}"
    npx wrangler containers list 2>/dev/null || echo "No containers deployed yet"
    
    echo ""
    echo -e "${YELLOW}Images:${NC}"
    npx wrangler containers images list 2>/dev/null || echo "No images deployed yet"
}

cf_logs() {
    print_header
    echo -e "${CYAN}==> Cloudflare Workers Logs${NC}"
    echo ""
    
    cd "$PROJECT_ROOT/workers"
    npx wrangler tail
}

cf_setup() {
    print_header
    echo -e "${CYAN}==> Setting up Cloudflare Resources${NC}"
    echo ""
    
    cd "$PROJECT_ROOT/workers"
    
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}==> Installing dependencies...${NC}"
        npm install
    fi
    
    echo -e "${YELLOW}==> Creating D1 Database...${NC}"
    echo "    Run this command to create the database:"
    echo ""
    echo -e "    ${GREEN}npx wrangler d1 create cutdeck-db${NC}"
    echo ""
    
    echo -e "${YELLOW}==> Creating KV Namespace...${NC}"
    echo "    Run this command to create the KV namespace:"
    echo ""
    echo -e "    ${GREEN}npx wrangler kv namespace create IMAGES${NC}"
    echo ""
    
    echo -e "${YELLOW}After creating resources, update ${GREEN}workers/wrangler.toml${NC} with the IDs.${NC}"
    echo ""
    
    read -p "Would you like to create these resources now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}Creating D1 database...${NC}"
        npx wrangler d1 create cutdeck-db || true
        echo ""
        echo -e "${YELLOW}Creating KV namespace...${NC}"
        npx wrangler kv namespace create IMAGES || true
        echo ""
        echo -e "${GREEN}Resources created! Update wrangler.toml with the IDs shown above.${NC}"
    fi
}

# =============================================================================
# MANAGEMENT COMMANDS
# =============================================================================
stop_services() {
    print_header
    echo -e "${YELLOW}==> Stopping all services...${NC}"
    docker-compose --profile tunnel --profile production down
    echo -e "${GREEN}==> All services stopped${NC}"
}

show_logs() {
    if [ -n "$1" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f
    fi
}

show_status() {
    print_header
    echo -e "${YELLOW}==> Service Status:${NC}"
    echo ""
    docker-compose --profile tunnel --profile production ps
}

build_images() {
    print_header
    echo -e "${YELLOW}==> Building all Docker images...${NC}"
    echo ""
    docker-compose --profile tunnel --profile production build
    echo ""
    echo -e "${GREEN}==> All images built successfully${NC}"
}

clean_all() {
    print_header
    echo -e "${RED}==> Cleaning all containers, images, and volumes...${NC}"
    echo ""
    read -p "Are you sure? This will remove all Cutdeck Docker resources. (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose --profile tunnel --profile production down -v --rmi all
        echo ""
        echo -e "${GREEN}==> Cleanup complete${NC}"
    else
        echo -e "${YELLOW}==> Cleanup cancelled${NC}"
    fi
}

# =============================================================================
# MAIN COMMAND ROUTER
# =============================================================================
case "$1" in
    setup)
        setup_tunnel
        ;;
    dev)
        run_dev "$2"
        ;;
    frontend)
        run_frontend
        ;;
    backend)
        run_backend
        ;;
    prod)
        run_prod "$2"
        ;;
    tunnel)
        run_tunnel "$2"
        ;;
    cf:deploy)
        cf_deploy
        ;;
    cf:dev)
        cf_dev
        ;;
    cf:status)
        cf_status
        ;;
    cf:logs)
        cf_logs
        ;;
    cf:setup)
        cf_setup
        ;;
    stop)
        stop_services
        ;;
    logs)
        show_logs "$2"
        ;;
    status)
        show_status
        ;;
    build)
        build_images
        ;;
    clean)
        clean_all
        ;;
    *)
        usage
        exit 1
        ;;
esac
