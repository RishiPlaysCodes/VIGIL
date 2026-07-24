#!/bin/sh
set -e

# Run database migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Start Gunicorn bound to Cloud Run's PORT (defaults to 8080)
echo "Starting Gunicorn on port ${PORT:-8080}..."
exec gunicorn pocket_guardian_backend.wsgi:application \
    --bind "0.0.0.0:${PORT:-8080}" \
    --workers 2 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
