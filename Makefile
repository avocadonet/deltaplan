# Makefile для удобного управления проектом deltaplan

# Определение компоуз-файла для продакшена
DC_PROD = docker-compose -f docker-compose.prod.yml

.PHONY: help up down logs build migrate seed makemigrations shell

help:
	@echo "Доступные команды:"
	@echo "  make up          - Запустить все сервисы в фоновом режиме"
	@echo "  make down        - Остановить и удалить все сервисы"
	@echo "  make logs        - Показать логи всех сервисов"
	@echo "  make build       - Пересобрать образы сервисов"
	@echo "  make migrate     - Выполнить миграции базы данных"
	@echo "  make seed        - Заполнить базу тестовыми данными"
	@echo "  make makemigrations - Создать новые файлы миграций"
	@echo "  make shell       - Запустить интерактивную оболочку в контейнере бэкенда"


up:
	$(DC_PROD) up --build -d

down:
	$(DC_PROD) down

logs:
	$(DC_PROD) logs -f

build:
	$(DC_PROD) build

migrate:
	$(DC_PROD) exec backend_prod python manage.py migrate

seed:
	$(DC_PROD) exec backend_prod python manage.py seed_db

makemigrations:
	$(DC_PROD) exec backend_prod python manage.py makemigrations

shell:
	$(DC_PROD) exec backend_prod /bin/sh