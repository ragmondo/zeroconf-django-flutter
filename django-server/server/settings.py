from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = 'minimal-mdns-poc'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'api',
]

MIDDLEWARE = []

ROOT_URLCONF = 'server.urls'

DATABASES = {}  # No database needed for this POC

USE_TZ = True