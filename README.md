# **Образовательно-досуговая платформа "Дельта"**

"Дельта" — это комплексная платформа для организации учебной и внеклассной жизни лицея. Проект включает в себя бэкенд на Django для управления данными и API, а также клиентское приложение на Flutter для взаимодействия с пользователями.

## **⚙️ Архитектура и технологии**

Проект построен по клиент-серверной архитектуре и использует следующий стек технологий:

*   **Бэкенд:** Python, Django, Django REST Framework.
*   **Фронтенд:** Dart, Flutter (поддерживает Android, iOS, Web).
*   **База данных:** PostgreSQL.
*   **Развертывание и оркестрация:** Docker, Docker Compose.
*   **Production-окружение:** Gunicorn (как WSGI-сервер) и Nginx (как реверс-прокси).

Бэкенд и база данных запускаются в изолированных Docker-контейнерах, что обеспечивает надежность, переносимость и простоту развертывания.

## **🛠️ Первоначальная настройка (выполняется один раз)**

Перед началом работы убедитесь, что на вашем устройстве установлены:
1.  **Docker и Docker Compose:** [Инструкция по установке](https://docs.docker.com/get-docker/).
2.  **Flutter SDK:** [Инструкция по установке](https://flutter.dev/docs/get-started/install).
3.  **Git:** для клонирования репозитория.

### **Шаг 1: Клонирование проекта**

```bash
git clone https://github.com/avocadonet/deltaplan.git
cd delta
```
### **Шаг 2: Настройка переменных окружения (Backend)**

1.  В папке `backend/` найдите файл `.env` или создайте его на основе файла `.env.example` (если он есть).
2.  Заполните его необходимыми данными. Для локальной разработки базовой конфигурации будет достаточно. **Никогда не храните production-секреты в Git!**

#### **Пример содержимого файла `backend/.env`:**
```dotenv
# Ключ для Django. Может быть любой длинной случайной строкой.
SECRET_KEY='django-insecure-your-development-key'

# Режим отладки. 'True' для разработки, 'False' для продакшена.
DEBUG=True

# Разрешенные хосты для разработки
ALLOWED_HOSTS=localhost,127.0.0.1

# Настройки для базы данных
POSTGRES_DB=deltaplan
POSTGRES_USER=user
POSTGRES_PASSWORD=password
DB_HOST=postgres
DB_PORT=5432
```

### **Шаг 3: Настройка локального домена (для Production-режима)**
Чтобы протестировать production-сборку локально, нам нужно "создать" домен `deltaplan.local`.

1.  **Откройте файл `hosts` от имени администратора:**
    *   **Windows:** `C:\Windows\System32\drivers\etc\hosts`
    *   **macOS/Linux:** `/etc/hosts`
2.  Добавьте в конец файла следующую строку:
    ```
    127.0.0.1       deltaplan.local www.deltaplan.local
    ```
3.  Сохраните файл.


## **🚀 Инструкции по запуску**

Существует два режима запуска проекта: для разработки и для симуляции продакшена.

### **Режим 1: Локальная разработка (Local Development)**

Этот режим используется для написания кода. Он включает **hot-reload** для бэкенда, что позволяет видеть изменения без перезапуска контейнеров.

#### **Запуск Backend + База данных:**
В корневой папке проекта выполните команду:
```bash
# Используем docker compose (без дефиса)
docker compose up --build
```
*   Бэкенд будет доступен по адресу `http://localhost:8000/`.
*   API, соответственно, на `http://localhost:8000/api/`.

#### **Применение миграций (если нужно):**
Команда `migrate` уже встроена в команду запуска, но если вы создали новые миграции в процессе работы, выполните:
```bash
docker compose exec backend python manage.py migrate
```

#### **Запуск Frontend (Flutter):**
1.  Убедитесь, что в `frontend/lib/api_service.dart` базовый URL указывает на сервер разработки:
    *   `http://127.0.0.1:8000/api/` (для Web, macOS, Windows)
    *   `http://10.0.2.2:8000/api/` (для Android-эмулятора)
2.  Запустите приложение как обычно:
    ```bash
    cd frontend
    flutter pub get
    flutter run -d chrome # или на эмуляторе
    ```

#### **Остановка режима разработки:**
```bash
docker compose down
```


### **Режим 2: Продакшен-сборка (Production Mode)**

Этот режим симулирует работу проекта на реальном сервере. Используется **Nginx** как реверс-прокси и **Gunicorn** как сервер приложений. Hot-reload отключен.

#### **Предварительная настройка (один раз):**
1.  **Настройте `.env` для продакшена:**
    В файле `backend/.env` установите `DEBUG=False` и добавьте ваш локальный домен в `ALLOWED_HOSTS`:
    ```dotenv
    DEBUG=False
    ALLOWED_HOSTS=deltaplan.local,www.deltaplan.local,localhost,127.0.0.1
    ```
2.  **Настройте Nginx:**
    В файле `nginx/nginx.conf` убедитесь, что `server_name` настроен на `deltaplan.local`.

#### **Запуск Production-сборки:**
Используем оба `docker-compose` файла для объединения конфигураций:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```
*   Сайт будет доступен по адресу **`http://deltaplan.local:8080/`**.
*   API, соответственно, на **`http://deltaplan.local:8080/api/`**.
*   **Примечание:** Мы используем порт `8080`, так как стандартный порт `80` может быть занят системными службами Windows (WSL).

#### **Применение миграций для Production-базы (важно!):**
Production-режим использует отдельную базу данных. При первом запуске или после добавления новых миграций их нужно применить:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec backend python manage.py migrate
```

#### **Создание суперпользователя в Production-базе:**
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml exec backend python manage.py createsuperuser
```
Теперь вы можете войти в админ-панель по адресу `http://deltaplan.local:8080/admin/`.

#### **Остановка Production-сборки:**
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
```

## **✅ Проверка работоспособности**

1.  **Backend (Production):** Откройте в браузере `http://deltaplan.local:8080/api/events/`. Вы должны увидеть JSON-ответ (пустой массив `[]` при первом запуске).
2.  **Frontend:** Запустите Flutter-приложение (не забудьте поменять URL в `api_service.dart` на `http://deltaplan.local:8080/api/`). Зарегистрируйтесь, войдите, проверьте разные экраны.

## **🗂️ Структура ролей и права доступа**

*   **Летопись выпускников:**
    *   **Просмотр:** Все аутентифицированные пользователи.
    *   **Создание:** Все аутентифицированные пользователи (запись уходит на модерацию).
*   **Родительский клуб:**
    *   **Просмотр и создание:** Родители, учителя, администраторы.
*   **И т.д.** (можно дополнить по необходимости)

```