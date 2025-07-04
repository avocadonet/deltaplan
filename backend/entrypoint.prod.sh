#!/bin/sh

# Устанавливаем переменную окружения, чтобы Django нашел свои настройки.
export DJANGO_SETTINGS_MODULE=deltaplan.settings

echo "Applying database migrations..."
python manage.py migrate --no-input

echo "Collecting static files..."
python manage.py collectstatic --no-input

# Запускаем основной процесс Gunicorn.
echo "Starting Gunicorn..."
exec "$@"