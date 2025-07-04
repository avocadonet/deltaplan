#!/bin/sh

echo "Applying database migrations..."
python manage.py migrate --no-input

echo "Collecting static files..."
python manage.py collectstatic --no-input

# Запускаем основной процесс, переданный в docker-compose (gunicorn)
# exec "$@" - это ["gunicorn", "deltaplan.wsgi:application", "--bind", "0.0.0.0:8000"]
echo "Starting Gunicorn..."
exec "$@"