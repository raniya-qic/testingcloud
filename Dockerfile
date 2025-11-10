# Lightweight Python image
FROM python:3.12-slim

# Prevent .pyc and ensure unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Workdir
WORKDIR /app

# Install Python deps first (layer cache)
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# (Optional) collect static at build time; ignore if not configured
RUN python manage.py collectstatic --noinput || true

# --- ENTRYPOINT (single, final) ---
# Normalize Windows line endings and make script executable
COPY entrypoint.sh /app/entrypoint.sh
RUN sed -i 's/\r$//' /app/entrypoint.sh && chmod +x /app/entrypoint.sh

# Start the app (migrate -> gunicorn)
CMD ["/app/entrypoint.sh"]
