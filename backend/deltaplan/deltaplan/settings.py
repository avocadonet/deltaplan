import os
from pathlib import Path
from datetime import timedelta

# --- Базовые настройки ---

# BASE_DIR указывает на корень Django-проекта (папка, где находится manage.py)
# backend/deltaplan/
BASE_DIR = Path(__file__).resolve().parent.parent

# Корень всего приложения внутри Docker-контейнера.
# Мы определили его как /app в Dockerfile.
APP_DIR = BASE_DIR.parent


# --- Безопасность и Переменные окружения ---

# Секретный ключ. Обязательно должен быть задан в .env файле.
SECRET_KEY = os.environ.get('SECRET_KEY')

# Режим отладки. По умолчанию ВЫКЛЮЧЕН для безопасности.
# Включается только если DEBUG=True в .env файле.
DEBUG = os.environ.get('DEBUG', 'False').lower() in ('true', '1', 't')

# Разрешенные хосты. Берем из переменной окружения, разделенной запятыми.
# Например: ALLOWED_HOSTS=127.0.0.1,localhost,mydomain.com
ALLOWED_HOSTS_STR = os.environ.get('ALLOWED_HOSTS', '')
ALLOWED_HOSTS = [host.strip() for host in ALLOWED_HOSTS_STR.split(',') if host.strip()]


# --- Приложения и Middleware ---

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
    "whitenoise.middleware.WhiteNoiseMiddleware", # Добавлено для обслуживания статики
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]


# --- Настройки CORS (Cross-Origin Resource Sharing) ---

# В режиме отладки разрешаем запросы с любого источника (удобно для локальной разработки)
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ORIGIN_ALLOW_ALL = True
else:
    # В продакшене разрешаем только с конкретных доменов, которые тоже берутся из .env
    # Например: CORS_ALLOWED_ORIGINS=https://mydomain.com,http://localhost:3000
    CORS_ALLOWED_ORIGINS_STR = os.environ.get('CORS_ALLOWED_ORIGINS', '')
    CORS_ALLOWED_ORIGINS = [origin.strip() for origin in CORS_ALLOWED_ORIGINS_STR.split(',') if origin.strip()]

# Можно также использовать CORS_TRUSTED_ORIGINS, если ваш фронтенд на том же домене,
# но другом порту (например, localhost:8000 и localhost:3000)

CORS_ALLOW_HEADERS = [
    'accept',
    'authorization',
    'content-type',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]


# --- URL-ы и Шаблоны ---

ROOT_URLCONF = "deltaplan.urls"
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


# --- База данных ---

DATABASES = {
    "default": {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('POSTGRES_DB'),
        'USER': os.environ.get('POSTGRES_USER'),
        'PASSWORD': os.environ.get('POSTGRES_PASSWORD'),
        'HOST': os.environ.get('DB_HOST'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}


# --- Аутентификация и Авторизация ---

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
}


# --- Интернационализация ---

LANGUAGE_CODE = "ru-ru"
TIME_ZONE = "Europe/Moscow"
USE_I18N = True
USE_TZ = True


# --- Статические и медиа файлы ---
# Это ключевые настройки для работы в Docker.

STATIC_URL = '/static/'
MEDIA_URL = '/media/'

# Пути внутри контейнера. Nginx будет забирать файлы из этих папок.
STATIC_ROOT = os.path.join(APP_DIR, 'staticfiles')
MEDIA_ROOT = os.path.join(APP_DIR, 'media')

# Добавлено для WhiteNoise (упрощает раздачу статики в dev режиме)
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'


# --- Прочее ---

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"