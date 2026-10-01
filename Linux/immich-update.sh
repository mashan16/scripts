#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/root/immich-app"
DATE=$(date +%d-%m-%Y)

step() { echo -e "\n\033[1;36m[$1/6]\033[0m \033[1m$2\033[0m"; }

step 1 "Обновление пакетов ОС"
apt update && apt upgrade -y && apt autoremove -y

step 2 "Переход в $APP_DIR"
cd "$APP_DIR"

step 3 "Бэкап docker-compose.yml"
mv docker-compose.yml "docker-compose.yml.${DATE}.bak"

step 4 "Скачивание актуального docker-compose.yml"
if ! wget -q --show-progress https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml; then
    echo -e "\033[1;31mОшибка скачивания, откатываю бэкап\033[0m"
    mv "docker-compose.yml.${DATE}.bak" docker-compose.yml
    exit 1
fi

step 5 "Обновление образов и запуск контейнеров"
docker compose pull && docker compose up -d

step 6 "Очистка старых образов docker"
docker system prune -a -f

echo -e "\n\033[1;32mГотово. Immich обновлён.\033[0m"
