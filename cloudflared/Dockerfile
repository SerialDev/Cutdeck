FROM cloudflare/cloudflared:latest

WORKDIR /etc/cloudflared

# Copy configuration
COPY config.yml ./

# Note: You'll need to mount the credentials file at runtime
# docker run -v ~/.cloudflared:/root/.cloudflared cloudflared-frontend

CMD ["tunnel", "run"]
