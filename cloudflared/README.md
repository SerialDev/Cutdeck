# Cloudflare Tunnel Configuration

This folder contains the Cloudflare Tunnel (cloudflared) configuration for exposing Cutdeck services to the internet securely.

## What is Cloudflare Tunnel?

Cloudflare Tunnel creates a secure, outbound-only connection between your services and Cloudflare's edge network. This allows you to:

- Expose local services without opening firewall ports
- Get automatic HTTPS/TLS encryption
- Benefit from Cloudflare's DDoS protection and WAF
- No need for a static IP or port forwarding

## Prerequisites

1. A Cloudflare account
2. A domain managed by Cloudflare
3. `cloudflared` CLI installed locally (for initial setup)

## Setup Instructions

### Option 1: Using launch.sh (Recommended)

```bash
# From project root
./launch.sh setup
```

This will:
1. Open browser for Cloudflare authentication
2. Create a tunnel named "cutdeck"
3. Display the tunnel ID for configuration

### Option 2: Manual Setup

```bash
# 1. Authenticate with Cloudflare
cloudflared tunnel login

# 2. Create tunnel
cloudflared tunnel create cutdeck

# 3. Note the tunnel ID from the output
```

## Configuration

After setup, edit `config.yml`:

1. Replace `<TUNNEL_ID>` with your actual tunnel ID
2. Replace `<YOUR_DOMAIN>` with your domain (e.g., `cutdeck.io`)

## DNS Records

Create DNS records in Cloudflare dashboard pointing to your tunnel:

| Type  | Name | Content                    |
|-------|------|----------------------------|
| CNAME | @    | <TUNNEL_ID>.cfargotunnel.com |
| CNAME | www  | <TUNNEL_ID>.cfargotunnel.com |
| CNAME | api  | <TUNNEL_ID>.cfargotunnel.com |

Or use the CLI:
```bash
cloudflared tunnel route dns cutdeck cutdeck.io
cloudflared tunnel route dns cutdeck www.cutdeck.io
cloudflared tunnel route dns cutdeck api.cutdeck.io
```

## Running the Tunnel

```bash
# With docker-compose (includes tunnel profile)
./launch.sh tunnel

# Or manually
docker-compose --profile tunnel up
```

## Files

- `config.yml` - Tunnel routing configuration
- `Dockerfile` - Container for running cloudflared
