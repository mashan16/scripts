# scripts

Bash и PowerShell скрипты для администрирования серверов.

---

## Linux

**install_update_tg_ws_proxy.sh** — установка и обновление [tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) (MTProxy для Telegram через WebSocket). Автоматически получает последнюю версию с GitHub, устанавливает зависимости (Python venv), создаёт и запускает systemd-сервис. Поддерживает Debian/Ubuntu, CentOS/RHEL/Fedora. Требует root.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/install_update_tg_ws_proxy.sh | bash
```

**stress_cpu.sh** — искусственная нагрузка на CPU через `stress-ng`. Без аргументов запускается в интерактивном режиме. Параметры: количество ядер (`-c`), процент нагрузки (`-p`), длительность в секундах (`-t`), файл лога (`-l`). При отсутствии `stress-ng` устанавливает его автоматически.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/stress_cpu.sh | bash
```

---

## Windows

### PowerShell (.ps1)

Запускаются через PowerShell напрямую или скачиваются вручную.

**win11_classic_menu.ps1** — возвращает классическое контекстное меню Windows 11 при нажатии правой кнопки мыши.

```powershell
irm https://raw.githubusercontent.com/mashan16/scripts/main/Windows/win11_classic_menu.ps1 | iex
```

### Batch (.bat)

Только для ручного скачивания и запуска — выполнение через командную строку cmd или powershell.

**PC_Reboot.bat** — принудительная перезагрузка по таймеру (30 сек) с возможностью отменить нажав 1.

**disk_usage_auto_clean.bat** *(archive)* — автоматическая очистка дискового пространства.
