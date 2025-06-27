# backend/Dockerfile - ДЛЯ ЛОКАЛЬНОЙ РАЗРАБОТКИ

# 1. Базовый образ
FROM python:3.11-slim-bookworm

# 2. Установка системных зависимостей, ВКЛЮЧАЯ NETCAT
#    --no-install-recommends экономит место.
RUN apt-get update && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. Установка рабочей директории
WORKDIR /app

# 4. Установка зависимостей Python
#    Копируем только requirements.txt для лучшего кэширования Docker-слоев.
#    Если зависимости не менялись, Docker не будет переустанавливать их при каждой сборке.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Копирование entrypoint-скрипта и выдача прав на исполнение
#    Предполагается, что entrypoint.sh лежит в той же папке backend/
COPY entrypoint.sh .
RUN chmod +x /app/entrypoint.sh

# 6. Копирование остального кода
#    Это нужно, чтобы образ был "целым", хотя для разработки мы его перекроем volume'ом.
COPY . .

# 7. Запуск от root (проще для локальной разработки с volumes)
#    Мы не используем `USER app` здесь

# 8. Указываем скрипт входа
ENTRYPOINT ["/app/entrypoint.sh"]

# 9. Команда по умолчанию - запуск dev-сервера Django
#    Эта команда будет передана как аргумент в entrypoint.sh
CMD ["python", "deltaplan/manage.py", "runserver", "0.0.0.0:8000"]