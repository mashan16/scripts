#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

function Write-Step { param($n, $total, $msg) Write-Host "[$n/$total] $msg" -ForegroundColor Yellow }
function Write-Ok   { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Err  { param($msg) Write-Host "Ошибка: $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }

Write-Info "============================================"
Write-Info "    Установщик Zabbix Agent 2 (Windows)"
Write-Info "============================================"
Write-Host ""

# --- Обнаружение установленного агента ---
$InstalledEntry = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
                                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" `
    -ErrorAction SilentlyContinue |
    Get-ItemProperty -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "Zabbix Agent 2*" } |
    Select-Object -First 1

if ($InstalledEntry) {
    $InstalledVersion = $InstalledEntry.DisplayVersion
    Write-Host "Обнаружен установленный Zabbix Agent 2:" -ForegroundColor Yellow
    Write-Host "  Версия:  $InstalledVersion" -ForegroundColor Cyan

    $ConfPath = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
    if (Test-Path $ConfPath) {
        $CurrentServer = (Select-String -Path $ConfPath -Pattern '^Server=(.+)' | Select-Object -First 1).Matches.Groups[1].Value
        if ($CurrentServer) { Write-Host "  Сервер:  $CurrentServer" -ForegroundColor Cyan }
    }

    Write-Host ""
    $Confirm = Read-Host "Переустановить? [y/N]"
    if ($Confirm -ne "y") {
        Write-Host "Отмена." -ForegroundColor DarkGray
        exit 0
    }

    Write-Host "Останавливаем сервис..." -ForegroundColor Yellow
    Stop-Service -Name "Zabbix Agent 2" -Force -ErrorAction SilentlyContinue

    Write-Host "Удаляем агент..." -ForegroundColor Yellow
    $ProductCode = $InstalledEntry.PSChildName
    $unProc = Start-Process msiexec.exe -ArgumentList "/x `"$ProductCode`" /qn" -Wait -PassThru -NoNewWindow
    if ($unProc.ExitCode -ne 0) {
        Write-Err "Не удалось удалить агент (код $($unProc.ExitCode))"
        exit 1
    }
    Write-Ok "Агент удалён. Продолжаем установку..."
    Write-Host ""
}

# --- Адрес сервера ---
do {
    $ZabbixServer = Read-Host "Адрес Zabbix сервера (IP или hostname)"
} while ([string]::IsNullOrWhiteSpace($ZabbixServer))

# --- Режим мониторинга ---
Write-Host ""
Write-Host "Режим мониторинга:" -ForegroundColor Yellow
Write-Host "  1. Passive — сервер сам подключается к агенту (порт 10050). Агент ждёт запросов."
Write-Host "  2. Active  — агент сам отправляет данные на сервер. Удобно если агент за NAT."
Write-Host "  3. Оба     — рекомендуется: работают параллельно, покрывают оба сценария."
Write-Host ""

do {
    $ModeChoice = Read-Host "Выберите режим [1/2/3]"
} while ($ModeChoice -notin @("1", "2", "3"))

$ServerParam       = if ($ModeChoice -in @("1","3")) { $ZabbixServer } else { "" }
$ServerActiveParam = if ($ModeChoice -in @("2","3")) { $ZabbixServer } else { "" }

# --- Последняя версия ---
Write-Host ""
Write-Step 1 5 "Определяем последнюю версию Zabbix Agent 2..."

try {
    $Page = Invoke-WebRequest -Uri "https://www.zabbix.com/download_agents" -UseBasicParsing -TimeoutSec 15
    $Matches2 = [regex]::Matches($Page.Content, 'zabbix_agent2-([\d]+\.[\d]+\.[\d]+)-windows-amd64')
    if ($Matches2.Count -eq 0) { throw "Версия не найдена в HTML" }
    $Version = $Matches2 |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object { [version]$_ } |
        Select-Object -Last 1
    Write-Ok "Последняя версия: $Version"
} catch {
    Write-Host "Не удалось определить версию автоматически: $_" -ForegroundColor Red
    do {
        $Version = Read-Host "Введите версию вручную (например: 7.4.0)"
    } while ($Version -notmatch '^\d+\.\d+\.\d+$')
}

$MajorMinor = ($Version -split '\.')[0..1] -join '.'
$MsiUrl     = "https://cdn.zabbix.com/zabbix/binaries/stable/$MajorMinor/$Version/zabbix_agent2-$Version-windows-amd64-openssl.msi"
$TempMsi    = "$env:TEMP\zabbix_agent2-$Version.msi"

# --- Скачивание ---
Write-Step 2 5 "Скачиваем zabbix_agent2-$Version-windows-amd64-openssl.msi..."

try {
    Invoke-WebRequest -Uri $MsiUrl -OutFile $TempMsi -UseBasicParsing
    Write-Ok "Скачано: $TempMsi"
} catch {
    Write-Err "Не удалось скачать: $MsiUrl`n$_"
    exit 1
}

# --- Установка ---
Write-Step 3 5 "Устанавливаем Zabbix Agent 2..."

$Hostname = $env:COMPUTERNAME
$MsiArgs  = "/i `"$TempMsi`" /qn SERVER=`"$ServerParam`" SERVERACTIVE=`"$ServerActiveParam`" HOSTNAME=`"$Hostname`""

$proc = Start-Process msiexec.exe -ArgumentList $MsiArgs -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) {
    Write-Err "msiexec завершился с кодом $($proc.ExitCode)"
    exit 1
}
Write-Ok "Установлено."

# --- Firewall ---
Write-Step 4 5 "Открываем порт 10050 (TCP, входящий)..."

$existingRule = Get-NetFirewallRule -DisplayName "Zabbix Agent 2" -ErrorAction SilentlyContinue
if ($existingRule) {
    Write-Host "Правило уже существует, пропускаем." -ForegroundColor DarkGray
} else {
    New-NetFirewallRule -DisplayName "Zabbix Agent 2" -Direction Inbound -Protocol TCP -LocalPort 10050 -Action Allow | Out-Null
    Write-Ok "Правило добавлено."
}

# --- Сервис ---
Write-Step 5 5 "Запускаем сервис..."

$ServiceName = "Zabbix Agent 2"
try {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    $Status = (Get-Service -Name $ServiceName).Status
    if ($Status -eq "Running") {
        Write-Ok "Сервис запущен ($Status)."
    } else {
        Write-Err "Сервис не запустился (статус: $Status). Проверьте логи."
        exit 1
    }
} catch {
    Write-Err "Не удалось запустить сервис: $_"
    exit 1
}

# --- Итог ---
Write-Host ""
Write-Info "============================================"
Write-Info "        Установка завершена успешно!"
Write-Info "============================================"
Write-Host "Хост:    $Hostname"     -ForegroundColor Cyan
Write-Host "Сервер:  $ZabbixServer" -ForegroundColor Cyan
Write-Host "Версия:  $Version"      -ForegroundColor Cyan
$modeLabel = @{ "1" = "Passive"; "2" = "Active"; "3" = "Active + Passive" }[$ModeChoice]
Write-Host "Режим:   $modeLabel"    -ForegroundColor Cyan
Write-Host ""

Remove-Item $TempMsi -Force -ErrorAction SilentlyContinue
