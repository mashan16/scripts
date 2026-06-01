#Requires -RunAsAdministrator

Write-Host "=== Создание ключа реестра: Классическое контекстное меню Windows 11 ===" -ForegroundColor Cyan

$regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"

New-Item -Path $regPath -Force | Out-Null
Write-Host "Ключ реестра создан." -ForegroundColor Green

Write-Host "=== Перезапуск проводника ===" -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Process explorer

Write-Host "=== Готово! ===" -ForegroundColor Green
