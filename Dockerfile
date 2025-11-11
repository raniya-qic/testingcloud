# Use Python slim image
FROM python:3.11-slim

# Prevent Python from writing .pyc and buffer output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Create app dir
WORKDIR /app

# System deps (psycopg/pg8000 may require these)
RUN apt-get update && apt-get install -y gcc build-essential && rm -rf /var/lib/apt/lists/*

# Copy requirements first (better caching)
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app

# Collect static at build time (bakes static into the container image)
# Provide minimal env for collectstatic to run
ENV DJANGO_SECRET_KEY="build-time"
ENV DJANGO_DEBUG="False"
RUN python manage.py collectstatic --noinput

# Cloud Run sets $PORT; default to 8080
ENV PORT=8080

# Gunicorn command
CMD exec gunicorn hostingtest.wsgi:application --bind 0.0.0.0:$PORT --workers 2 --threads 8 --timeout 0
