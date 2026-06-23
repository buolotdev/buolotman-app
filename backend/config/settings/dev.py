import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.dev')

from .base import *

DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1']

# Use Neon PostgreSQL in dev
import dj_database_url
DATABASES = {
    'default': dj_database_url.config(
        default=config('DATABASE_URL'),
        conn_max_age=600,
        ssl_require=True,
    )
}



STATIC_ROOT = BASE_DIR / 'staticfiles'
