# Описание скриптов

**install_update_tg_ws_proxy.sh** — установка и обновление [tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) (MTProxy для Telegram через WebSocket). Автоматически получает последнюю версию с GitHub, устанавливает зависимости (Python venv), создаёт и запускает systemd-сервис. Поддерживает Debian/Ubuntu, CentOS/RHEL/Fedora. Требует root.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/install_update_tg_ws_proxy.sh | bash
```

**stress_cpu.sh** — искусственная нагрузка на CPU через `stress-ng`. Параметры: количество ядер (`-c`), процент нагрузки (`-p`), длительность в секундах (`-t`), файл лога (`-l`). При отсутствии `stress-ng` устанавливает его автоматически.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/stress_cpu.sh | bash
```
