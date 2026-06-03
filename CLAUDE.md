# scripts

Репозиторий bash/PowerShell скриптов для администрирования серверов.

## Структура

- `Linux/` — bash-скрипты для Linux-серверов
- `Windows/` — bat/ps1 скрипты для Windows

## Соглашения

- Bash-скрипты: проверка root, цветной вывод (RED/GREEN/YELLOW/CYAN), `set -e`
- Поддержка дистрибутивов: Debian/Ubuntu и CentOS/RHEL/Fedora
- Сервисы оформляются как systemd-юниты
- Секреты хранятся в отдельных файлах с ограниченными правами (600), не в основном скрипте

## Окружение

- Разработка: Windows 11, VSCode
- Целевые серверы: Linux (Debian, Ubuntu, CentOS, RHEL, Fedora)
- Деплой через Remote SSH
