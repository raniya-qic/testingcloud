# Dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# System deps for psycopg2 and Pillow (if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# Collect static into /app/staticfiles (uses your Whitenoise config)
# You can no-op this locally by setting DJANGO_SETTINGS_MODULE if needed
ENV DJANGO_SETTINGS_MODULE=hostingtest.settings
RUN python manage.py collectstatic --noinput

# Use a non-root user (best practice)
RUN useradd -m appuser
USER appuser

# Cloud Run provides $PORT; Gunicorn must bind to it
ENV PORT=8080
EXPOSE 8080

# Start Gunicorn
# Replace 'hostingtest.wsgi' with your actual WSGI module if different
CMD exec gunicorn hostingtest.wsgi:application --bind 0.0.0.0:$PORT --workers 2 --threads 4 --timeout 120
