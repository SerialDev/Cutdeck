# Cutdeck

A modern full-stack application built with React 19, TypeScript, and Python, designed for deployment on Cloudflare's edge network using **Cloudflare Containers**.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 19 + TypeScript + Vite |
| Backend | Cloudflare Containers (Python + FastAPI + DaggyD) |
| Database | Cloudflare D1 (SQLite at the edge) |
| Image Storage | Cloudflare Workers KV |
| CI/CD | GitHub Actions |
| Hosting | Cloudflare Pages |
| Local Dev | Docker Compose |
| Tunneling | Cloudflare Tunnel (cloudflared) |

## Project Structure

```
Cutdeck/
├── frontend/                 # React 19 + TypeScript + Vite
│   ├── src/
│   │   ├── App.tsx          # Main application component
│   │   ├── main.tsx         # Entry point
│   │   └── *.css            # Styles
│   ├── public/              # Static assets
│   ├── Dockerfile           # Multi-stage build (dev/prod)
│   ├── nginx.conf           # Production nginx config
│   ├── package.json
│   ├── tsconfig.json
│   └── vite.config.ts
│
├── backend/                  # Python + FastAPI + DaggyD
│   ├── main.py              # FastAPI application
│   ├── Dockerfile           # Python 3.13 + uv (linux/amd64)
│   ├── pyproject.toml       # Dependencies
│   └── uv.lock
│
├── workers/                  # Cloudflare Workers + Containers
│   ├── src/
│   │   └── index.ts         # Worker entry point
│   ├── wrangler.toml        # Cloudflare configuration
│   ├── package.json
│   └── tsconfig.json
│
├── cloudflared/             # Cloudflare Tunnel configuration
│   ├── config.yml           # Tunnel routing rules
│   ├── Dockerfile           # cloudflared container
│   └── README.md            # Setup instructions
│
├── docker-compose.yml       # Service orchestration
├── launch.sh                # CLI for managing services
└── README.md
```

## Quick Start

### Prerequisites

- Docker & Docker Compose
- Node.js 22+ (for Workers development)
- Python 3.13+ (for local backend development)
- Wrangler CLI (`npm install -g wrangler`)
- cloudflared CLI (optional, for tunnel setup)

### Development Mode

Start the full development environment with hot reload:

```bash
# Start frontend + backend locally
./launch.sh dev

# Or start in detached mode
./launch.sh dev -d
```

Access the services:
- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs

### Individual Services

```bash
# Frontend only
./launch.sh frontend

# Backend only
./launch.sh backend
```

## Cloudflare Containers Deployment

Cloudflare Containers lets you run your Docker containers directly on Cloudflare's edge network. Your Python + DaggyD backend runs as a serverless container, managed by a Worker.

### Deploy to Cloudflare

```bash
# First time: login to Cloudflare
wrangler login

# Deploy backend container + worker
./launch.sh cf:deploy
```

This will:
1. Build the backend Docker image (linux/amd64)
2. Push the image to Cloudflare's container registry
3. Deploy the Worker that manages the container
4. Your app is live at `https://cutdeck.<your-account>.workers.dev`

### Cloudflare Commands

```bash
# Deploy to Cloudflare Containers
./launch.sh cf:deploy

# Local development with Workers
./launch.sh cf:dev

# Check container status
./launch.sh cf:status

# View container logs
./launch.sh cf:logs

# Setup D1 database and KV namespace
./launch.sh cf:setup
```

### How It Works

```
┌─────────────┐     ┌────────────────────────────────────────────────────┐
│  Internet   │────▶│              Cloudflare Edge Network               │
│  (HTTPS)    │     │                                                    │
└─────────────┘     │  ┌──────────────┐      ┌───────────────────────┐  │
                    │  │    Worker    │─────▶│  Backend Container    │  │
                    │  │  (Router)    │      │  (Python + DaggyD)    │  │
                    │  └──────────────┘      └───────────────────────┘  │
                    │         │                        │                │
                    │         ▼                        ▼                │
                    │  ┌──────────────┐      ┌───────────────────────┐  │
                    │  │     D1       │      │    Workers KV         │  │
                    │  │  (Database)  │      │  (Image Storage)      │  │
                    │  └──────────────┘      └───────────────────────┘  │
                    └────────────────────────────────────────────────────┘
```

The Worker acts as a router/controller:
- Routes `/api/*` requests to the Python container
- Handles health checks and status
- Manages container lifecycle (auto-sleep after 10 min inactivity)

## Cloudflare Tunnel (Alternative)

If you prefer to run containers locally but expose them to the internet:

### Step 1: Setup Tunnel

```bash
./launch.sh setup
```

### Step 2: Configure

Edit `cloudflared/config.yml`:
- Replace `<TUNNEL_ID>` with your tunnel ID
- Replace `<YOUR_DOMAIN>` with your domain

### Step 3: Run with Tunnel

```bash
./launch.sh tunnel
```

## Launch Script Commands

```bash
./launch.sh <command> [options]

# Development (Local Docker)
dev             Start frontend + backend for local development
dev -d          Start in detached mode
frontend        Start only the frontend (React + Vite)
backend         Start only the backend (FastAPI + DaggyD)

# Production (Local Docker)
prod            Start production build (nginx + backend)
prod -d         Start production in detached mode

# Cloudflare Tunnel
setup           Authenticate and create cloudflared tunnel
tunnel          Start all services WITH cloudflare tunnel
tunnel -d       Start tunnel services in detached mode

# Cloudflare Containers (Edge Deployment)
cf:deploy       Deploy backend to Cloudflare Containers
cf:dev          Run Workers in local development mode
cf:status       Show container deployment status
cf:logs         View container logs
cf:setup        Setup Cloudflare resources (D1, KV)

# Management
stop            Stop all running services
logs [service]  View logs (optionally for specific service)
status          Show status of all services
build           Build all Docker images
clean           Remove all containers, images, and volumes
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | API information |
| GET | `/health` | Health check |
| GET | `/api/docs` | Swagger API documentation |
| GET | `/api/daggyd/test` | Test DaggyD graph execution |
| GET | `/_container/status` | Container status (Workers only) |

## Cloudflare Services

### D1 Database

SQLite database at the edge for low-latency data access.

Setup:
```bash
# Create database
wrangler d1 create cutdeck-db

# Update workers/wrangler.toml with the database ID
```

### Workers KV

Key-value storage for images and cache.

Setup:
```bash
# Create KV namespace
wrangler kv namespace create IMAGES

# Update workers/wrangler.toml with the namespace ID
```

### Pages (Frontend Hosting)

Deploy the frontend to Cloudflare Pages:
```bash
cd frontend
npm run build
wrangler pages deploy dist --project-name cutdeck
```

## Architecture Comparison

### Option 1: Cloudflare Containers (Recommended for Production)

```
Internet → Cloudflare Edge → Worker → Container (Python + DaggyD)
                               ↓
                          D1 + KV
```

**Pros:**
- Serverless - no servers to manage
- Auto-scaling
- Global edge deployment
- Pay per use

### Option 2: Cloudflare Tunnel (Good for Development)

```
Internet → Cloudflare Edge → Tunnel → Your Machine → Docker
```

**Pros:**
- Run on your own hardware
- Full control over environment
- Good for development/testing

## Environment Variables

### Workers (wrangler.toml)

```toml
[vars]
ENVIRONMENT = "production"
```

### Backend (Dockerfile/docker-compose)

```yaml
environment:
  - PYTHONUNBUFFERED=1
  - ENVIRONMENT=production
```

### Frontend (.env)

```env
VITE_API_URL=http://localhost:8000
```

## Development

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Backend

```bash
cd backend
uv sync
uv run uvicorn main:app --reload
```

### Workers

```bash
cd workers
npm install
npx wrangler dev
```

## Troubleshooting

### Container Deployment Issues

```bash
# Check container status
./launch.sh cf:status

# View logs
./launch.sh cf:logs

# Redeploy
./launch.sh cf:deploy
```

### Local Docker Issues

```bash
# View logs
./launch.sh logs

# Rebuild images
./launch.sh build

# Clean and restart
./launch.sh clean
./launch.sh dev
```

### Tunnel Issues

```bash
# Check tunnel status
cloudflared tunnel list

# Delete and recreate
cloudflared tunnel delete cutdeck
./launch.sh setup
```

## License

MIT
