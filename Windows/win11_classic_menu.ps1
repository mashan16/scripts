# Проверка прав администратора
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Запусти скрипт от имени администратора!" -ForegroundColor Red
    pause
    exit
}

Write-Host "=== Создание ключа реестра: Классическое контекстное меню Windows 11 ===" -ForegroundColor Cyan

reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /f | Out-Null

Write-Host "Ключ реестра создан." -ForegroundColor Green

Write-Host "=== Перезапуск проводника ===" -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Wait-Process -Name explorer -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process explorer

Write-Host "=== Готово! ===" -ForegroundColor Green