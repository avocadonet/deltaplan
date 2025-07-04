# ==============================================================================
#           Файл настроек Django для проекта "Дельта"
#      Оптимизирован для работы в Docker-окружении (Prod & Dev)
# ==============================================================================

import os
from pathlib import Path
from datetime import timedelta
from dotenv import load_dotenv

# --- Шаг 1: Определение базовых путей ---

# Загружаем переменные из .env файла в окружение.
# Это нужно, чтобы Django мог их видеть при запуске через Gunicorn или manage.py.
load_dotenv()

# BASE_DIR - это корневая директория вашего Django-проекта, где лежит manage.py.
# В нашем Docker-контейнере это /app.
# __file__ -> /app/deltaplan/settings.py
# .parent -> /app/deltaplan
# .parent.parent -> /app
BASE_DIR = Path(__file__).resolve().parent.parent


# --- Шаг 2: Безопасность и основные параметры ---

# Секретный ключ. ОБЯЗАТЕЛЬНО должен быть задан в .env файле.
SECRET_KEY = os.environ.get('SECRET_KEY')
if not SECRET_KEY:
    raise ValueError("Необходимо установить SECRET_KEY в .env файле!")

# Режим отладки. По умолчанию ВЫКЛЮЧЕН для безопасности.
# Включается только если DEBUG=True (или 1, t) в .env файле.
DEBUG = os.environ.get('DEBUG', 'False').lower() in ('true', '1', 't')

# Разрешенные хосты. Берем из переменной окружения, разделенной запятыми.
# В режиме отладки разрешаем все для удобства, в продакшене - только конкретные.
if DEBUG:
    ALLOWED_HOSTS = ['*']
else:
    ALLOWED_HOSTS_STR = os.environ.get('ALLOWED_HOSTS')
    if not ALLOWED_HOSTS_STR:
        raise ValueError("В продакшен-режиме (DEBUG=False) необходимо указать ALLOWED_HOSTS!")
    ALLOWED_HOSTS = [host.strip() for host in ALLOWED_HOSTS_STR.split(',') if host.strip()]

# Доверяем заголовку X-Forwarded-Proto, который устанавливает Nginx.
# Этот заголовок говорит Django, что исходное соединение было по HTTPS.
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Требовать безопасные куки. Браузер будет отправлять их только по HTTPS.
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Предотвращение кликджекинга
X_FRAME_OPTIONS = 'DENY'

# --- Шаг 3: Конфигурация приложений ---

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Сторонние приложения
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",
    # Ваши приложения
    "app",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    # WhiteNoise УБРАН, так как Nginx занимается статикой в продакшене.
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware", # Должен быть как можно выше
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

# --- Шаг 4: Настройки маршрутизации и шаблонов ---

ROOT_URLCONF = "deltaplan.urls"
# Путь к WSGI-приложению для Gunicorn.
WSGI_APPLICATION = "deltaplan.wsgi.application"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]


# --- Шаг 5: Настройки базы данных ---

DATABASES = {
    "default": {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB'),
        'USER': os.environ.get('POSTGRES_USER'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'), # Имя сервиса в docker-compose
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}


# --- Шаг 6: Аутентификация, авторизация и DRF ---

AUTH_USER_MODEL = 'app.User'

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.IsAuthenticated',
    )
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
    "ROTATE_REFRESH_TOKENS": True, # Опционально, но безопасно
}


# --- Шаг 7: Настройки CORS (Cross-Origin Resource Sharing) ---
# Эта настройка позволяет вашему фронтенду (Flutter Web) делать запросы к API.

if DEBUG:
    # В режиме разработки разрешаем всё для удобства.
    CORS_ALLOW_ALL_ORIGINS = True
else:
    # В продакшене разрешаем запросы только с конкретных доменов из .env
    CORS_ALLOWED_ORIGINS_STR = os.environ.get('CORS_ALLOWED_ORIGINS')
    if not CORS_ALLOWED_ORIGINS_STR:
        raise ValueError("В продакшен-режиме (DEBUG=False) необходимо указать CORS_ALLOWED_ORIGINS!")
    CORS_ALLOWED_ORIGINS = [origin.strip() for origin in CORS_ALLOWED_ORIGINS_STR.split(',') if origin.strip()]


# --- Шаг 8: Интернационализация ---

LANGUAGE_CODE = "ru-ru"
TIME_ZONE = "Europe/Moscow"
USE_I18N = True
USE_TZ = True


# --- Шаг 9: Статические и медиа файлы ---
# Эти пути должны точно совпадать с путями томов в docker-compose.yml

STATIC_URL = '/static/'
MEDIA_URL = '/media/'

# Абсолютные пути внутри контейнера, куда Django будет собирать статику
# и сохранять медиа-файлы. Nginx будет читать из этих же путей.
STATIC_ROOT = '/app/staticfiles'
MEDIA_ROOT = '/app/media'


# --- Шаг 10: Прочие настройки ---

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"