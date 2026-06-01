Write-Host "=== Создание ключа реестра: Классическое контекстное меню Windows 11 ===" -ForegroundColor Cyan

$regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
New-Item -Path $regPath -Force | Out-Null
Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force

Write-Host "Ключ реестра создан." -ForegroundColor Green

Write-Host "=== Перезапуск проводника ===" -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Wait-Process -Name explorer -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Start-Process explorer

Write-Host "=== Готово! ===" -ForegroundColor Green