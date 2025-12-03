# =============================================================================
# Cutdeck Backend - Python + FastAPI + DaggyD
# =============================================================================
# This Dockerfile works for both:
# - Local Docker development
# - Cloudflare Containers deployment (requires linux/amd64)
# =============================================================================

FROM --platform=linux/amd64 python:3.13-slim

WORKDIR /app

# Install git (required for uv to clone DaggyD from GitHub)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN pip install uv

# Copy project files
COPY pyproject.toml uv.lock .python-version ./

# Install dependencies using uv
RUN uv sync

# Copy application code
COPY main.py ./

# Expose port
EXPOSE 8000

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Run the application with uvicorn
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
