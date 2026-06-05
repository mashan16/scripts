#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Сброс цвета

# Обработка прерывания Ctrl+C
trap "echo -e '\n${YELLOW}Прерывание! Останавливаем нагрузку...${NC}'; exit" INT

# Параметры по умолчанию
CORES=1
PERCENT=50
DURATION=60
LOGFILE="stress.log"

# Функция для вывода справки
show_help() {
    echo -e "${GREEN}Использование: $0 [параметры]${NC}"
    echo "Параметры:"
    echo "  -c N    Количество ядер для нагрузки (по умолчанию: $CORES)"
    echo "  -p N    Процент нагрузки на ядро (1-100, по умолчанию: $PERCENT)"
    echo "  -t N    Длительность нагрузки в секундах (по умолчанию: $DURATION)"
    echo "  -l FILE Файл для логов (по умолчанию: $LOGFILE)"
    echo "  -h      Показать эту справку"
    echo -e "\nПример: $0 -c 2 -p 75 -t 30 -l mylog.txt"
    exit 0
}

# Разбор аргументов командной строки
while getopts ":c:p:t:l:h" opt; do
    case $opt in
        c) CORES="$OPTARG" ;;
        p) PERCENT="$OPTARG" ;;
        t) DURATION="$OPTARG" ;;
        l) LOGFILE="$OPTARG" ;;
        h) show_help ;;
        \?) echo -e "${RED}Неизвестный параметр: -$OPTARG${NC}" >&2; exit 1 ;;
        :) echo -e "${RED}Для параметра -$OPTARG требуется значение.${NC}" >&2; exit 1 ;;
    esac
done

# Проверка наличия stress-ng
if ! command -v stress-ng &> /dev/null; then
    echo -e "${GREEN}Установка stress-ng...${NC}"
    if command -v sudo &> /dev/null; then
        sudo apt update && sudo apt install -y stress-ng
    else
        apt update && apt install -y stress-ng
    fi || {
        echo -e "${RED}Ошибка установки stress-ng${NC}"
        exit 1
    }
fi

# Проверка параметров
if ! [[ "$CORES" =~ ^[0-9]+$ ]] || [ "$CORES" -gt "$(nproc)" ] || [ "$CORES" -lt 1 ]; then
    echo -e "${RED}Ошибка: количество ядер должно быть от 1 до $(nproc)${NC}" >&2
    exit 1
fi

if ! [[ "$PERCENT" =~ ^[0-9]+$ ]] || [ "$PERCENT" -gt 100 ] || [ "$PERCENT" -lt 1 ]; then
    echo -e "${RED}Ошибка: процент нагрузки должен быть от 1 до 100${NC}" >&2
    exit 1
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo -e "${RED}Ошибка: длительность должна быть больше 0 секунд${NC}" >&2
    exit 1
fi

# Логгирование
echo "$(date): Загружаем $CORES ядер на $PERCENT% в течение $DURATION сек." >> "$LOGFILE"

# Запуск нагрузки
echo -e "${GREEN}Настройки нагрузки:${NC}"
echo -e "  Ядер: ${YELLOW}$CORES${NC}"
echo -e "  Нагрузка: ${YELLOW}$PERCENT%${NC} на ядро"
echo -e "  Длительность: ${YELLOW}$DURATION${NC} сек."
echo -e "  Лог-файл: ${YELLOW}$LOGFILE${NC}"
echo -e "${GREEN}Запуск нагрузки...${NC}"

stress-ng --cpu "$CORES" --cpu-load "$PERCENT" --timeout "${DURATION}s" || {
    echo -e "${RED}Ошибка выполнения stress-ng${NC}" >&2
    exit 1
}

echo -e "${GREEN}Нагрузка успешно завершена.${NC}"
exit 0
