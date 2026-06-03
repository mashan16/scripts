@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set SECONDS=15


echo ============================================
echo   ⚠️ ВНИМАНИЕ! Принудительная перезагрузка!
echo   Все приложения будут закрыты БЕЗ сохранения!
echo   ПК перезагрузится через !SECONDS! секунд...
echo   Нажмите CTRL+C и затем Y, чтобы отменить
echo ============================================


:countdown
if !SECONDS! leq 0 goto reboot
echo Осталось: !SECONDS! сек.
set /a SECONDS-=1
timeout /t 1 >nul
goto countdown

:reboot
echo Перезагрузка...
shutdown /r /f /t 30 /c "Через 30 секунд с начала появления этого уведомления"
