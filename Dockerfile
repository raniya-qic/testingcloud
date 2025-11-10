# Lightweight Python image
FROM python:3.12-slim

# Prevents Python from writing .pyc files & buffering stdout
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Cloud Run sets $PORT; default for local build
    PORT=8080

# System deps (build + runtime)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Workdir
WORKDIR /app

# Install Python deps first (better layer caching)
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# Collect static at build time (safe even if none configured)
# You can skip this and do it at runtime in entrypoint.sh if preferred.
RUN python manage.py collectstatic --noinput || true

# Cloud Run passes $PORT; Gunicorn must bind 0.0.0.0:$PORT
# Replace "hostingtest.wsgi" with "<yourproject>.wsgi"
CMD exec gunicorn hostingtest.wsgi:application \
    --bind 0.0.0.0:${PORT} \
    --workers 2 \
    --threads 4 \
    --timeout 120

    # Copy entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run the entrypoint (migrate, then gunicorn)
CMD ["/app/entrypoint.sh"]