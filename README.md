# scripts

Bash,PowerShell,Bath скрипты для Windows и GNU\Linux.

---

## Linux

### **install_update_tg_ws_proxy.sh**

Установка и обновление [tg-ws-proxy](https://github.com/Flowseal/tg-ws-proxy) (MTProxy для Telegram через WebSocket). Автоматически получает последнюю версию с GitHub, устанавливает зависимости (Python venv), создаёт и запускает systemd-сервис. Поддерживает Debian/Ubuntu, CentOS/RHEL/Fedora. Требует root.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/install_update_tg_ws_proxy.sh | bash
```

### **stress_cpu.sh**

 Искусственная нагрузка на CPU через `stress-ng`. Без аргументов — интерактивный режим. Параметры: количество ядер (`-c`), процент нагрузки (`-p`), длительность в секундах (`-t`), файл лога (`-l`). При отсутствии `stress-ng` устанавливает его автоматически.

```bash
curl -s https://raw.githubusercontent.com/mashan16/scripts/main/Linux/stress_cpu.sh | bash
```

---

## Windows

## PowerShell (.ps1)

Запускаются через PowerShell напрямую или скачиваются вручную.

### **install-zabbix-agent.ps1**

 установка и переустановка Zabbix Agent 2. Автоматически определяет последнюю версию, настраивает режим мониторинга (Active/Passive/Оба), открывает порт 10050. При повторном запуске обнаруживает установленный агент и предлагает переустановить.

```powershell
irm https://raw.githubusercontent.com/mashan16/scripts/main/Windows/install-zabbix-agent.ps1 | iex
```

> **Windows Server 2016 и ниже** использует PowerShell где есть только TLS 1.0 по умолчанию, из-за чего `irm` не может подключиться к GitHub. Перед запуском выполните:
>
> ```powershell
> [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
> ```
>
> Команда ниже переключает протокол на TLS 1.2 для текущей сессии PowerShell — после этого irm сможет подключиться к GitHub:

### **win11_classic_menu.ps1** — возвращает классическое контекстное меню Windows 11 при нажатии правой кнопки мыши

```powershell
irm https://raw.githubusercontent.com/mashan16/scripts/main/Windows/win11_classic_menu.ps1 | iex
```

## Batch (.bat)

Только для ручного скачивания и запуска — выполнение через командную строку cmd или powershell.

### **PC_Reboot.bat**

Принудительная перезагрузка по таймеру (30 сек) с возможностью отменить нажав 1.
[Скачать](https://raw.githubusercontent.com/mashan16/scripts/main/Windows/PC_Reboot.bat)

### **disk_usage_auto_clean.bat** *(archive)*

Автоматическая очистка дискового пространства.
[Скачать](https://raw.githubusercontent.com/mashan16/scripts/main/Windows/archive/disk_usage_auto_clean.bat)
