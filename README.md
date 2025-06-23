# **Образовательно-досуговая платформа "Дельта"**

"Дельта" — это комплексная платформа для организации учебной и внеклассной жизни лицея. Проект включает в себя бэкенд на Django для управления данными и API, а также клиентское приложение на Flutter для взаимодействия с пользователями.

## **⚙️ Архитектура и технологии**

Проект построен по клиент-серверной архитектуре и использует следующий стек технологий:

*   **Бэкенд:** Python, Django, Django REST Framework.
*   **Фронтенд:** Dart, Flutter (поддерживает Android, iOS, Web).
*   **База данных:** PostgreSQL.
*   **Развертывание и оркестрация:** Docker, Docker Compose.
*   **Production-сервер:** Gunicorn (как WSGI-сервер) и Nginx (как реверс-прокси).

В производственном режиме Nginx выступает как единая точка входа, раздавая веб-приложение Flutter и проксируя API-запросы на бэкенд.

## **🛠️ Первоначальная настройка (выполняется один раз)**

Перед началом работы убедитесь, что на вашем устройстве установлены:
1.  **Docker и Docker Compose:** [Инструкция по установке](https://docs.docker.com/get-docker/).
2.  **Flutter SDK:** [Инструкция по установке](https://flutter.dev/docs/get-started/install).
3.  **Git:** для клонирования репозитория.

### Шаг 1: Клонирование проекта

```bash
git clone https://github.com/avocadonet/deltaplan.git
cd deltaplan
```

### Шаг 2: Настройка переменных окружения

Для работы проекта требуются файлы с переменными окружения для бэкенда.

1.  **Для разработки:** Создайте в папке `backend/` файл `.env` на основе примера ниже.
2.  **Для продакшена:** Создайте в папке `backend/` файл `.env_prod` на основе примера ниже.

**Никогда не храните production-секреты в Git!** Файлы `.env` и `.env_prod` уже добавлены в `.gitignore`.

#### **Пример `backend/.env` (для разработки):**
```dotenv
# Ключ для Django. Может быть любой длинной случайной строкой.
SECRET_KEY='django-insecure-your-secret-key-for-development'

# Режим отладки. 'True' для разработки.
DEBUG=True

# Разрешенные хосты (для разработки можно оставить '*')
ALLOWED_HOSTS=*

# Настройки для базы данных разработки
POSTGRES_DB=deltaplan_dev
POSTGRES_USER=user_dev
POSTGRES_PASSWORD=password_dev
DB_HOST=postgres_dev
DB_PORT=5432
```

#### **Пример `backend/.env_prod` (для продакшена):**
```dotenv
# Сгенерируйте надежный ключ для продакшена!
SECRET_KEY='your-super-secret-and-long-production-key'

# Отладка в продакшене должна быть выключена!
DEBUG=False

# Укажите домен вашего сайта и IP-адрес сервера.
# Для локального тестирования добавьте localhost и 127.0.0.1
ALLOWED_HOSTS=your_domain.com,www.your_domain.com,127.0.0.1,localhost

# Настройки для production базы данных
POSTGRES_DB=deltaplan_prod
POSTGRES_USER=user_prod
POSTGRES_PASSWORD=super_secret_password_prod
DB_HOST=postgres_prod
DB_PORT=5432
```

## **🚀 Режим 1: Локальная разработка (Local Development)**

Этот режим используется для написания и отладки кода. Он включает **hot-reload** для бэкенда и фронтенда. Nginx не используется.

### **Запуск Backend + База данных:**
В корневой папке проекта выполните команду:
```bash
# Используем docker-compose.yml, который предназначен для разработки.
# --build нужен только при первом запуске или после изменения Dockerfile/зависимостей.
docker compose up
```
*   Бэкенд будет доступен по адресу `http://localhost:8000/`.
*   API, соответственно, на `http://localhost:8000/api/`.

### **Запуск Frontend (Flutter):**
Flutter-приложение в режиме разработки настроено на использование `http://...:8000/api/` по умолчанию.

1.  Откройте новый терминал.
2.  Запустите приложение как обычно:
    ```bash
    cd frontend
    flutter pub get
    flutter run -d chrome  # выберите ваше устройство (chrome, эмулятор и т.д.)
    ```

### **Остановка режима разработки:**
Чтобы остановить все контейнеры, связанные с разработкой, выполните:
```bash
docker compose down
```

## **🚀 Режим 2: Тестирование Production-сборки**

Этот режим симулирует работу проекта на реальном сервере. Используется **Nginx** как реверс-прокси, **Gunicorn** как сервер приложений, и **веб-сборка Flutter**. Hot-reload **отключен**.

### **Шаг 1: Сборка веб-приложения Flutter**
Перед первым запуском или после внесения изменений во фронтенд, соберите его с указанием URL для продакшена.
```bash
cd frontend
flutter build web --dart-define=API_URL=http://127.0.0.1:8080/api/ --dart-define=API_URL_ANDROID=http://10.0.2.2:8080/api/
cd ..
```
Эта команда создаст папку `frontend/build/web`, которую Nginx будет раздавать как сайт.

### **Шаг 2: Запуск Production-сборки**
Используем отдельный `docker-compose.prod.yml` файл.
```bash
# Флаг -f указывает, какой файл использовать.
# Флаг -d (detach) запускает контейнеры в фоновом режиме.
docker compose -f docker-compose.prod.yml up --build -d
```
*   Ваш сайт будет доступен по адресу **`http://127.0.0.1:8080/`**.
*   Запросы к API, которые делает Flutter-приложение, будут автоматически направляться на `http://127.0.0.1:8080/api/`.

### **Шаг 3: Выполнение команд Django (Миграции и Суперпользователь)**
Команды выполняются аналогично режиму разработки, но с указанием production-файла.

*   **Применение миграций** (обязательно при первом запуске!):
    ```bash
    docker compose -f docker-compose.prod.yml exec backend_prod python manage.py migrate
    ```
*   **Создание суперпользователя** (для доступа к админ-панели на `http://127.0.0.1:8080/admin/`):
    ```bash
    docker compose -f docker-compose.prod.yml exec backend_prod python manage.py createsuperuser
    ```

### **Проверка логов:**
Чтобы посмотреть логи работающих в фоне контейнеров:
```bash
docker compose -f docker-compose.prod.yml logs -f backend_prod
docker compose -f docker-compose.prod.yml logs -f nginx
```

### **Остановка Production-сборки:**
```bash
docker compose -f docker-compose.prod.yml down
```
Эта команда остановит и удалит все контейнеры, связанные с production-окружением (`_prod`).