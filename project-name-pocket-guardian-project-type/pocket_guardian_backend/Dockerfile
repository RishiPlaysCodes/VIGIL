# ─── Production Dockerfile for Pocket Guardian Backend ────────────────────────
# Multi-stage build for minimal image size

FROM python:3.12-slim AS base

# Prevent Python from buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/*

# ─── Dependencies Stage ──────────────────────────────────────────────────────
FROM base AS dependencies

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ─── Production Stage ─────────────────────────────────────────────────────────
FROM base AS production

# Copy installed packages from dependencies stage
COPY --from=dependencies /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=dependencies /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Collect static files (uses a temporary build-only secret key)
RUN DJANGO_BUILD_STEP=1 python manage.py collectstatic --noinput

# Create media directory
RUN mkdir -p /app/media

# Cloud Run injects the PORT env var (default 8080). Gunicorn must bind to it.
ENV PORT=8080
EXPOSE 8080

# Entrypoint runs migrations then starts the server
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
