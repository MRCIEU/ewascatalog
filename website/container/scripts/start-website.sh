#!/bin/bash

: "${DATABASE_NAME:?database name missing}"
: "${DATABASE_USER:?database username missing}"
: "${DATABASE_PASSWORD:?database password missing}"
: "${WEBSITE_PORT:?django website port}"
: "${DJANGO_SETTINGS_MODULE:?Django settings missing}"
: "${SECRET_KEY:?Django secret key missing}"
: "${DJANGO_EMAIL:?Django email missing}"
: "${DJANGO_EMAIL_PASSWORD:?Django email password missing}"

. /opt/venv/bin/activate

echo "Django website starting up ..."
cd /django

export DATABASE_USER
export DATABASE_PASSWORD
export DATABASE_NAME
export DJANGO_SETTINGS_MODULE
export SECRET_KEY
export DJANGO_EMAIL
export DJANGO_EMAIL_PASSWORD

python manage.py migrate --noinput
python manage.py collectstatic --noinput
exec gunicorn --workers 3 --bind 0.0.0.0:${WEBSITE_PORT} website.wsgi:application


