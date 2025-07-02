#!/bin/sh

# Ожидаем, пока база данных будет готова
# (Это хорошая практика, но зависит от healthcheck, который у вас уже есть, так что можно пропустить)

echo "Applying database migrations..."
python manage.py migrate --no-input

echo "Collecting static files..."
python manage.py collectstatic --no-input

# Запускаем основной процесс, переданный в docker-compose (gunicorn)
exec "$@"