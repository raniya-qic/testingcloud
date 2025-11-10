#!/usr/bin/env bash
set -e

python manage.py collectstatic --noinput || true
python manage.py migrate --noinput

# Optional: auto-create superuser if env provided
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
python - <<'PYCODE'
import os
from django.contrib.auth import get_user_model
User = get_user_model()
u, created = User.objects.get_or_create(
    username=os.environ["DJANGO_SUPERUSER_USERNAME"],
    defaults={"email": os.environ["DJANGO_SUPERUSER_EMAIL"]},
)
if created:
    u.set_password(os.environ["DJANGO_SUPERUSER_PASSWORD"])
    u.is_staff = True
    u.is_superuser = True
    u.save()
print("Superuser ready.")
PYCODE
fi

exec gunicorn hostingtest.wsgi:application \
  --bind 0.0.0.0:${PORT:-8080} \
  --workers 2 --threads 4 --timeout 120
