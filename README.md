### Фрагмент 1: Общая информация (Начало файла)

Этот блок содержит описание проекта, стек технологий и шаги, которые нужно выполнить один раз перед первым запуском любого из режимов.

# **Образовательно-досуговая платформа "Дельта"**

"Дельта" — это комплексная платформа для организации учебной и внеклассной жизни лицея. Проект включает в себя бэкенд на Django для управления данными и API, а также клиентское приложение на Flutter для взаимодействия с пользователями.

## **⚙️ Архитектура и технологии**

Проект построен по клиент-серверной архитектуре и использует следующий стек технологий:

*   **Бэкенд:** Python, Django, Django REST Framework.
*   **Фронтенд:** Dart, Flutter (поддерживает Android, iOS, Web).
*   **База данных:** PostgreSQL.
*   **Развертывание и оркестрация:** Docker, Docker Compose.
*   **Production-сервер:** Gunicorn (как WSGI-сервер) и Nginx (как реверс-прокси).

Бэкенд и база данных запускаются в изолированных Docker-контейнерах, что обеспечивает надежность, переносимость и простоту развертывания.

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

Для работы проекта требуются файлы с переменными окружения.

1.  **Для разработки:** Создайте в папке `backend/` файл `.env`.
2.  **Для продакшена:** Создайте в корневой папке (`/`) файл `.env.prod`.

Вы можете создать их на основе примеров ниже. **Никогда не храните production-секреты в Git!**

#### **Пример содержимого файла `backend/.env` (для разработки):**
```dotenv
# Ключ для Django. Может быть любой длинной случайной строкой.
SECRET_KEY='django-insecure-your-secret-key-for-development'

# Режим отладки. 'True' для разработки, 'False' для продакшена.
DEBUG=True

# Разрешенные хосты (для разработки можно оставить '*')
ALLOWED_HOSTS=*

# Настройки для базы данных разработки
POSTGRES_DB=deltaplan_dev
POSTGRES_USER=user_dev
POSTGRES_PASSWORD=password_dev
# Имя хоста должно совпадать с именем сервиса в docker-compose.yml
DB_HOST=postgres_dev
DB_PORT=5432
```

#### **Пример содержимого файла `.env_prod` (для продакшена):**
```dotenv
# Сгенерируйте надежный ключ для продакшена!
SECRET_KEY='your-super-secret-and-long-production-key'

# Отладка в продакшене должна быть выключена!
DEBUG=False

# Укажите домен вашего сайта и IP-адрес сервера.
# Для локального тестирования прода: deltaplan.local,www.deltaplan.local,localhost,127.0.0.1
ALLOWED_HOSTS=your_domain.com,www.your_domain.com

# Настройки для production базы данных
POSTGRES_DB=deltaplan_prod
POSTGRES_USER=user_prod
POSTGRES_PASSWORD=super_secret_password_prod
# Имя хоста должно совпадать с именем сервиса в docker-compose.prod.yml
DB_HOST=postgres_prod
DB_PORT=5432
```

### Фрагмент 2: Инструкции для локальной разработки

Этот блок описывает, как запустить проект для ежедневной разработки с "горячей перезагрузкой".

## **🚀 Режим 1: Локальная разработка (Local Development)**

Этот режим используется для написания и отладки кода. Он включает **hot-reload** для бэкенда, что позволяет видеть изменения в Python-коде без полного перезапуска контейнера.

### **Запуск Backend + База данных:**
В корневой папке проекта выполните команду:
```bash
# Используем docker-compose.yml, который предназначен для разработки.
# --build нужен только при первом запуске или после изменения Dockerfile/зависимостей.
docker compose up
```
*   Бэкенд будет доступен по адресу `http://localhost:8000/`.
*   API, соответственно, на `http://localhost:8000/api/`.
*   База данных разработки будет доступна с вашего компьютера по порту `8082`.

### **Выполнение команд Django (миграции, суперпользователь):**
Откройте новый терминал и используйте `docker compose exec` для выполнения команд внутри работающего контейнера `backend_dev`.

*   **Применение миграций** (если вы создали новые):
    ```bash
    docker compose exec backend_dev python manage.py migrate
    ```
*   **Создание суперпользователя** (для доступа к админ-панели):
    ```bash
    docker compose exec backend_dev python manage.py createsuperuser
    ```

### **Запуск Frontend (Flutter):**
1.  Убедитесь, что в `frontend/lib/api_service.dart` базовый URL указывает на сервер разработки:
    *   `http://127.0.0.1:8000/api/` (для Web, macOS, Windows)
    *   `http://10.0.2.2:8000/api/` (для Android-эмулятора)
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


### Фрагмент 3: Инструкции для тестирования продакшен-сборки

Этот блок описывает, как локально запустить полноценную production-сборку с Nginx и Gunicorn для тестирования.


## **🚀 Режим 2: Тестирование Production-сборки**

Этот режим симулирует работу проекта на реальном сервере. Используется **Nginx** как реверс-прокси и **Gunicorn** как сервер приложений. Hot-reload **отключен**, код запекается в Docker-образ.

### **Предварительная настройка (один раз):**
Чтобы протестировать production-сборку локально с использованием "доменного имени", добавьте его в ваш файл `hosts`.
1.  Убедитесь, что в `frontend/lib/api_service.dart` базовый URL указывает на сервер разработки:
    *   `http://127.0.0.1:8080/api/` (для Web, macOS, Windows)
    *   `http://10.0.2.2:8080/api/` (для Android-эмулятора)

2.  **Откройте файл `hosts` от имени администратора:**
    *   **Windows:** `C:\Windows\System32\drivers\etc\hosts`
    *   **macOS/Linux:** `/etc/hosts`
3.  Добавьте в конец файла следующую строку и сохраните:
    ```
    127.0.0.1       deltaplan.local
    ```

### **Запуск Production-сборки:**
Используем отдельный `docker-compose.prod.yml` файл.

```bash
# Флаг -f указывает, какой файл использовать.
# Флаг -d (detach) запускает контейнеры в фоновом режиме.
docker compose -f docker-compose.prod.yml up --build -d
```
*   Сайт будет доступен по адресу **`http://deltaplan.local:8080/`**.
*   API, соответственно, на **`http://deltaplan.local:8080/api/`**.
*   **Примечание:** Мы используем порт `8080`, так как стандартный порт `80` может быть занят другими службами.

### **Выполнение команд Django в Production-контейнере:**
Команды выполняются аналогично, но указывается другой файл и имя контейнера (`backend_prod`).

*   **Применение миграций** (обязательно при первом запуске!):
    ```bash
    docker compose -f docker-compose.prod.yml exec backend_prod python deltaplan/manage.py migrate
    ```
*   **Создание суперпользователя** (для доступа к админ-панели):
    ```bash
    docker compose -f docker-compose.prod.yml exec backend_prod python deltaplan/manage.py createsuperuser
    ```
*   **Сбор статики** (если нужно вручную):
    ```bash
    docker compose -f docker-compose.prod.yml exec backend_prod python deltaplan/manage.py collectstatic --noinput
    ```

### **Проверка логов:**
Чтобы посмотреть логи работающего в фоне production-бэкенда:
```bash
docker compose -f docker-compose.prod.yml logs -f backend_prod
```

### **Остановка Production-сборки:**
```bash
docker compose -f docker-compose.prod.yml down
```
Эта команда остановит и удалит все контейнеры, связанные с production-окружением (`_prod`).
