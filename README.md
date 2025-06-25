# **Образовательно-досуговая платформа "Дельтаплан"**

"Дельтаплан" — это комплексная платформа для организации учебной и внеклассной жизни лицея. Проект включает в себя бэкенд на Django для управления данными и API, а также клиентское приложение на Flutter для взаимодействия с пользователями.

## **⚙️ Архитектура и технологии**

Проект построен по клиент-серверной архитектуре и использует следующий стек технологий:

*   **Бэкенд:** Python, Django, Django REST Framework.
*   **Фронтенд:** Dart, Flutter (поддерживает Android, iOS, Web).
*   **База данных:** PostgreSQL.
*   **Развертывание и оркестрация:** Docker, Docker Compose.
*   **Production-сервер:** Gunicorn (как WSGI-сервер) и Nginx (как реверс-прокси).

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

1.  **Для разработки:** В папке `backend/` создайте файл `.env`.
2.  **Для тестирования и продакшена:** В папке `backend/` создайте файл `.env_prod`.

**Никогда не храните production-секреты в Git!** Файлы `.env` и `.env_prod` уже добавлены в `.gitignore`.

#### **Пример `backend/.env` (для разработки):**
```dotenv
SECRET_KEY='django-insecure-your-secret-key-for-development'
DEBUG=True
ALLOWED_HOSTS=*
POSTGRES_DB=deltaplan_dev
POSTGRES_USER=user_dev
POSTGRES_PASSWORD=password_dev
DB_HOST=postgres_dev
DB_PORT=5432
```

#### **Пример `backend/.env_prod` (для тестирования/продакшена):**
В этом файле важно правильно настроить доступ к вашему серверу.
```dotenv
# Сгенерируйте надежный ключ для продакшена!
SECRET_KEY='your-super-secret-and-long-production-key'

# Отладка в продакшене должна быть выключена!
DEBUG=False

# Укажите домен вашего сайта и IP-адрес сервера.
# Для локального тестирования этого достаточно.
ALLOWED_HOSTS=your_domain.com,www.your_domain.com,127.0.0.1,localhost

# [ВАЖНО] Дополнительные источники для CORS, через запятую.
# Необходимо для подключения мобильных приложений по локальной сети.
# Укажите сюда IP-адрес вашего ноутбука. Пример:
EXTRA_CORS_ORIGINS=http://192.168.51.41:8080

# Настройки для production базы данных
POSTGRES_DB=deltaplan_prod
POSTGRES_USER=user_prod
POSTGRES_PASSWORD=super_secret_password_prod
DB_HOST=postgres_prod
DB_PORT=5432
```
**Примечание:** Для корректной работы CORS в Django `settings.py` должен быть настроен на чтение переменной `EXTRA_CORS_ORIGINS`.


## **🚀 Режим 1: Локальная разработка (Hot-Reload)**

Этот режим используется для написания и отладки кода. Он включает **hot-reload** для бэкенда и фронтенда. Nginx не используется.

### **Запуск Backend + База данных:**
В корневой папке проекта выполните команду:
```bash
# Используем docker-compose.yml, который предназначен для разработки.
docker compose up
```
*   Бэкенд будет доступен по адресу `http://localhost:8000/`.

### **Запуск Frontend (Flutter):**
Откройте новый терминал и запустите приложение на нужном устройстве:
```bash
cd frontend
flutter pub get
flutter run # выберите ваше устройство (chrome, эмулятор и т.д.)
```


## **🚀 Режим 2: Тестирование Production-сборки (локально)**

Этот режим симулирует работу проекта на реальном сервере. Используется **Nginx** и **Gunicorn**. Hot-reload **отключен**.

### **Шаг 0: Запуск Backend-сервера (Общий для всех тестов)**
Это первый и обязательный шаг для всех последующих ступеней тестирования.
```bash
# Флаг -f указывает, какой файл использовать.
# Флаг -d (detach) запускает контейнеры в фоновом режиме.
docker compose -f docker-compose.prod.yml up -d --build
```
При первом запуске не забудьте выполнить миграции и создать суперпользователя:
```bash
docker compose -f docker-compose.prod.yml exec backend_prod python manage.py migrate
docker compose -f docker-compose.prod.yml exec backend_prod python manage.py createsuperuser
```

### **Ступень 1: Тестирование Web-версии на ноутбуке**

**Цель:** Проверить работу веб-сборки в браузере на том же компьютере, где запущен сервер.

1.  **Сборка Web-версии:**
    ```bash
    cd frontend
    # Собираем web-версию, указывая, что API находится на том же хосте
    flutter build web --dart-define=API_URL=http://127.0.0.1:8080/api/
    cd ..
    ```
2.  **Проверка:** Откройте в браузере адрес **`http://localhost:8080`**. Сайт должен полностью функционировать, так как `localhost:8080` и `127.0.0.1:8080` по умолчанию разрешены в настройках CORS.

### **Ступень 2: Тестирование приложения на Android**

**Цель:** Собрать и установить `.apk` на реальный Android-телефон, который будет подключаться к серверу на ноутбуке по локальной Wi-Fi сети.

1.  **Настройка сети и `.env_prod`:**
    *   На телефоне включите режим "Точка доступа Wi-Fi".
    *   На ноутбуке подключитесь к этой сети и узнайте свой IP-адрес (команда `ipconfig` в Windows).
    *   Откройте файл `backend/.env_prod` и впишите IP-адрес вашего ноутбука в переменную `EXTRA_CORS_ORIGINS`. Пример:
      ```dotenv
      EXTRA_CORS_ORIGINS=http://192.168.51.41:8080
      ```
    *   **Перезапустите Docker-контейнеры**, чтобы они подхватили новые переменные: `docker compose -f docker-compose.prod.yml up -d`

2.  **Сборка `.apk` с правильным IP:**
    ```bash
    cd frontend
    # Замените <IP-АДРЕС-ВАШЕГО-НОУТБУКА> на реальный IP!
    flutter build apk --dart-define=API_URL_ANDROID=http://<IP-АДРЕС-ВАШЕГО-НОУТБУКА>:8080/api/
    ```
    Эта команда "запечет" IP-адрес сервера прямо в установочный файл.

3.  **Установка и тестирование:**
    *   Скопируйте сгенерированный файл `build/app/outputs/flutter-apk/app-release.apk` на ваш телефон.
    *   Установите его (может потребоваться разрешение на установку из неизвестных источников).
    *   Убедитесь, что `android:usesCleartextTraffic="true"` добавлено в тег `<application>` в файле `android/app/src/main/AndroidManifest.xml` для поддержки `http://`.
    *   Запустите приложение. Оно должно успешно подключаться к бэкенду.

### **Ступень 3: Тестирование приложения на iPhone**

**Цель:** Собрать и установить `.ipa` на iPhone. **Внимание: для этого шага требуется доступ к macOS!** Рекомендуется использовать облачные сервисы (Codemagic, Mac-in-the-Cloud).

1.  **Настройка сети и `.env_prod`:** Выполняется аналогично ступени 2 на вашем ноутбуке, где работает бэкенд.

2.  **Сборка `.ipa` с правильным IP (выполняется на macOS):**
    ```bash
    # Эта команда должна быть выполнена на компьютере с macOS!
    # Замените <IP-АДРЕС-ВАШЕГО-НОУТБУКА> на реальный IP!
    flutter build ipa --dart-define=API_URL_ANDROID=http://<IP-АДРЕС-ВАШЕГО-НОУТБУКА>:8080/api/
    ```

3.  **Установка и тестирование:**
    *   Перенесите полученный `.ipa` файл на ваш Windows-компьютер.
    *   Используйте утилиты вроде **Sideloadly** для установки `.ipa` файла на iPhone с помощью вашего Apple ID.
    *   Приложение, установленное с помощью бесплатного Apple ID, будет работать 7 дней.

---

## **Остановка и очистка**

*   **Остановка dev-окружения:**
    ```bash
    docker compose down
    ```
*   **Остановка prod-окружения:**
    ```bash
    docker compose -f docker-compose.prod.yml down
    ```
*   **Проверка логов:**
    ```bash
    docker compose -f docker-compose.prod.yml logs -f nginx
    docker compose -f docker-compose.prod.yml logs -f backend_prod
    ```