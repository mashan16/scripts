#!/bin/bash
# =============================================================================
# Скрипт обновления tg-ws-proxy
# Автоматически проверяет последнюю версию на GitHub,
# устанавливает её и создаёт systemd-сервис.
# =============================================================================

set -e  # Останавливать выполнение при любой ошибке

# --- Цвета для вывода в терминал ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Сброс цвета

# Проверка прав root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Ошибка: запустите скрипт с правами root (sudo bash $0)${NC}"
    exit 1
fi

# --- Репозиторий на GitHub ---
GITHUB_REPO="Flowseal/tg-ws-proxy"

# =============================================================================
# Проверяем и устанавливаем системные зависимости
# =============================================================================
echo -e "${YELLOW}[1/7] Проверяем системные зависимости...${NC}"

MISSING_PKGS=()

# Проверяем наличие каждого нужного инструмента
command -v git        &>/dev/null || MISSING_PKGS+=("git")
command -v python3    &>/dev/null || MISSING_PKGS+=("python3")
command -v curl       &>/dev/null || MISSING_PKGS+=("curl")
python3 -m venv --help &>/dev/null || MISSING_PKGS+=("python3-venv")

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Устанавливаем: ${MISSING_PKGS[*]}${NC}"
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y "${MISSING_PKGS[@]}"
    elif command -v dnf &>/dev/null; then
        dnf install -y "${MISSING_PKGS[@]}"
    elif command -v yum &>/dev/null; then
        yum install -y "${MISSING_PKGS[@]}"
    else
        echo -e "${RED}Ошибка: установите вручную: ${MISSING_PKGS[*]}${NC}"
        exit 1
    fi
    echo -e "${GREEN}Зависимости установлены.${NC}"
else
    echo -e "${GREEN}Все зависимости присутствуют.${NC}"
fi
echo ""
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
INSTALL_BASE="/opt"


echo -e "${CYAN}"
echo "============================================================"
echo "         Установщик / обновлятор tg-ws-proxy"
echo "============================================================"
echo -e "${NC}"

# =============================================================================
# ШАГ 1: Получаем последнюю версию с GitHub
# =============================================================================
echo -e "${YELLOW}[2/7] Проверяем последнюю версию на GitHub...${NC}"

# Запрашиваем GitHub API и извлекаем номер версии из поля "tag_name"
LATEST_VERSION=$(curl -s "${GITHUB_API}" | grep '"tag_name"' | sed 's/.*"tag_name": *"v\([^"]*\)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Ошибка: не удалось получить версию с GitHub. Проверьте интернет-соединение.${NC}"
    exit 1
fi

echo -e "${GREEN}Последняя версия: ${LATEST_VERSION}${NC}"

# Проверяем, не установлена ли уже эта версия
INSTALL_DIR="${INSTALL_BASE}/tg-ws-proxy-${LATEST_VERSION}"
SERVICE_FILE="/etc/systemd/system/tg-ws-proxy-${LATEST_VERSION}.service"

if [ -d "$INSTALL_DIR" ] && [ -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}Версия ${LATEST_VERSION} уже установлена в ${INSTALL_DIR}${NC}"
    echo -n "Переустановить? (y/n): "
    read -r REINSTALL </dev/tty
    if [ "$REINSTALL" != "y" ]; then
        echo "Выход."
        exit 0
    fi
    # Останавливаем существующий сервис перед переустановкой
    systemctl stop "tg-ws-proxy-${LATEST_VERSION}.service" 2>/dev/null || true
    rm -rf "$INSTALL_DIR"
fi

# =============================================================================
# ШАГ 2: Запрашиваем секрет (secret)
# =============================================================================
echo ""
echo -e "${YELLOW}[3/7] Настройка параметров прокси${NC}"
echo ""
echo -e "Посмотреть текущий secret можно командой:"
echo -e "${CYAN}  cat /etc/systemd/system/tg-ws-proxy-*.service | grep 'secret'${NC}"
echo -e "или"
echo -e "${CYAN}  systemctl cat tg-ws-proxy-*.service | grep 'secret'${NC}"
echo ""

while true; do
    echo -n "Введите secret (32 hex-символа, без префикса dd): "
    read -r SECRET </dev/tty

    # Проверяем что secret не пустой и содержит ровно 32 hex-символа
    if [[ "$SECRET" =~ ^[0-9a-fA-F]{32}$ ]]; then
        break
    else
        echo -e "${RED}Ошибка: secret должен содержать ровно 32 шестнадцатеричных символа (0-9, a-f).${NC}"
        echo -e "Пример: 58ed6572af2ee94cb7f80548cb3d63e9"
    fi
done

# =============================================================================
# ШАГ 3: Запрашиваем порт
# =============================================================================
echo ""

# Показываем какие порты уже заняты сервисами tg-ws-proxy
USED_PORTS=$(grep -h 'port' /etc/systemd/system/tg-ws-proxy-*.service 2>/dev/null | grep -oP '(?<=--port )\d+' | sort -u | tr '\n' ' ')
if [ -n "$USED_PORTS" ]; then
    echo -e "Уже используемые порты: ${CYAN}${USED_PORTS}${NC}"
fi

while true; do
    echo -n "Введите порт для новой версии (например 1084): "
    read -r PORT </dev/tty

    # Проверяем что порт — число в диапазоне 1024-65535
    if [[ "$PORT" =~ ^[0-9]+$ ]] && [ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ]; then
        # Проверяем что порт не занят
        if ss -tlnp | grep -q ":${PORT} "; then
            echo -e "${RED}Порт ${PORT} уже занят другим процессом. Выберите другой.${NC}"
        else
            break
        fi
    else
        echo -e "${RED}Ошибка: введите корректный порт (1024–65535).${NC}"
    fi
done

# =============================================================================
# ШАГ 4: Клонируем репозиторий и устанавливаем зависимости
# =============================================================================
echo ""
echo -e "${YELLOW}[4/7] Клонируем репозиторий v${LATEST_VERSION}...${NC}"

mkdir -p "$INSTALL_DIR"

# Клонируем конкретный тег, --depth 1 чтобы не тянуть всю историю
git clone --branch "v${LATEST_VERSION}" --depth 1 \
    "https://github.com/${GITHUB_REPO}.git" "$INSTALL_DIR"

echo ""
echo -e "${YELLOW}[5/7] Создаём виртуальное окружение и устанавливаем зависимости...${NC}"

# Создаём Python venv внутри папки установки
python3 -m venv "${INSTALL_DIR}/venv"

# Устанавливаем зависимости:
# - если есть requirements.txt (версии до 1.7.0) — используем его
# - если есть pyproject.toml (версии 1.7.0+) — устанавливаем через pip install -e
if [ -f "${INSTALL_DIR}/requirements.txt" ]; then
    echo "Найден requirements.txt, устанавливаем из него..."
    "${INSTALL_DIR}/venv/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"
elif [ -f "${INSTALL_DIR}/pyproject.toml" ]; then
    echo "Найден pyproject.toml, устанавливаем через pip install -e..."
    "${INSTALL_DIR}/venv/bin/pip" install -e "${INSTALL_DIR}/"
else
    echo -e "${RED}Ошибка: не найден ни requirements.txt, ни pyproject.toml${NC}"
    exit 1
fi

# =============================================================================
# ШАГ 5: Создаём systemd-сервис
# =============================================================================
echo ""
echo -e "${YELLOW}[6/7] Создаём systemd-сервис...${NC}"

# Сохраняем secret в отдельный файл с ограниченными правами (не виден в systemctl cat)
ENV_FILE="/etc/tg-ws-proxy-${LATEST_VERSION}.env"
echo "TG_SECRET=${SECRET}" > "$ENV_FILE"
chmod 600 "$ENV_FILE"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=tg-ws-proxy ${LATEST_VERSION}
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${INSTALL_DIR}/
EnvironmentFile=/etc/tg-ws-proxy-${LATEST_VERSION}.env
ExecStart=${INSTALL_DIR}/venv/bin/python proxy/tg_ws_proxy.py --host 0.0.0.0 --port ${PORT} --secret \$TG_SECRET
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Перечитываем конфиги systemd и запускаем сервис
systemctl daemon-reload
systemctl enable --now "tg-ws-proxy-${LATEST_VERSION}.service"

# =============================================================================
# ШАГ 6: Проверяем статус
# =============================================================================
echo ""
echo -e "${YELLOW}[7/7] Проверяем статус сервиса...${NC}"
sleep 3  # Даём сервису время запуститься

# Проверяем что сервис активен
if systemctl is-active --quiet "tg-ws-proxy-${LATEST_VERSION}.service"; then
    echo -e "${GREEN}"
    echo "============================================================"
    echo "  Установка успешно завершена!"
    echo "============================================================"
    echo -e "${NC}"
    echo -e "Версия:  ${CYAN}${LATEST_VERSION}${NC}"
    echo -e "Порт:    ${CYAN}${PORT}${NC}"
    echo -e "Сервис:  ${CYAN}tg-ws-proxy-${LATEST_VERSION}.service${NC}"
    echo ""
    echo -e "Ссылка для подключения (отправить в Telegram отдельным сообщением):"
    echo -e "${CYAN}https://t.me/proxy?server=$(hostname -I | awk '{print $1}')&port=${PORT}&secret=dd${SECRET}${NC}"
    echo ""
    echo "Статус сервиса:"
    systemctl status "tg-ws-proxy-${LATEST_VERSION}.service" --no-pager -l
else
    echo -e "${RED}"
    echo "============================================================"
    echo "  Ошибка: сервис не запустился!"
    echo "============================================================"
    echo -e "${NC}"
    echo "Логи:"
    journalctl -u "tg-ws-proxy-${LATEST_VERSION}.service" -n 20 --no-pager
    exit 1
fi

# --- Подсказка про старые версии ---
echo ""
OLD_SERVICES=$(ls /etc/systemd/system/tg-ws-proxy-*.service 2>/dev/null | grep -v "${LATEST_VERSION}" || true)
if [ -n "$OLD_SERVICES" ]; then
    echo -e "${YELLOW}Старые версии сервисов:${NC}"
    for svc in $OLD_SERVICES; do
        SVC_NAME=$(basename "$svc")
        STATUS=$(systemctl is-active "$SVC_NAME" 2>/dev/null || echo "unknown")
        echo -e "  ${SVC_NAME} — ${STATUS}"
    done
    echo ""
    echo -e "Чтобы остановить старую версию:"
    echo -e "${CYAN}  systemctl stop <имя_сервиса>${NC}"
    echo -e "${CYAN}  systemctl disable <имя_сервиса>${NC}"
fi
