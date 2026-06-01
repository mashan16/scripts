@echo off
chcp 65001 >nul

echo === Создание ключа реестра Классическое контекстное меню windows 11 ===
echo === Для классического контекстного меню windows 11 ===
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f

echo === Перезапуск проводника ===
powershell -Command "Stop-Process -Name explorer -Force; Start-Process explorer"

echo === Готово! ===
pause
