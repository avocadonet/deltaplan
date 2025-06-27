#!/bin/sh
# backend/entrypoint.sh - ИСПРАВЛЕНО

set -e

echo "Waiting for postgres..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 0.1
done
echo "PostgreSQL started"

echo "Applying database migrations..."
# ИСПРАВЛЕННЫЙ ПУТЬ
python deltaplan/manage.py migrate

# Эта команда выполнит то, что передано в "command" в docker-compose.yml
exec "$@"