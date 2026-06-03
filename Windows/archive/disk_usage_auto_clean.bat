:: Этот batch-скрипт проверяет заполненность указанного диска
:: (по умолчанию C:) и удаляет 10 старейших файлов из указанной папки (C:\apps),
:: если заполненность превышает 95%. 
:: Разберем его по частям: 
 :: 1. @echo off: Отключает отображение команд в консоли.
 :: 2. chcp 65001 >nul: Устанавливает кодировку консоли на UTF-8.  >nul подавляет вывод сообщения об успехе.
 :: 3. set drive=C: и set targetFolder=C:\apps:  Задают переменные для диска и целевой папки.  Их можно изменить.
 :: 4. for /f ...:  Эта часть использует PowerShell для получения процента заполненности диска.
 ::  * powershell -Command "...":  Выполняет команду PowerShell.
 ::  * Get-WmiObject Win32_LogicalDisk -Filter 'DeviceID=\"%drive%\"':  Получает информацию о логическом диске.
 ::  * ForEach-Object { ... }:  Обрабатывает каждый объект.
 ::  * $used = ($_.Size - $_.FreeSpace):  Вычисляет используемое пространство.
 ::  * $percent = [math]::Round(($used / $_.Size) * 100, 0):  Вычисляет процент заполненности и округляет до целого числа.
 ::  * Write-Output $percent:  Выводит процент в консоль.
 ::   * for /f "usebackq" %%P in (...) do (set percent=%%P):  Извлекает результат из вывода PowerShell и сохраняет его в переменной percent.
 ::
 :: 5. echo Debug ...:  Выводит отладочную информацию.
 :: 6. if not defined percent ...:  Проверяет, было ли успешно получено значение процента заполненности.
 :: 7. set percent=%percent: =%:  Удаляет все пробелы из переменной percent.
 :: 8. echo Drive ...:  Выводит процент заполненности диска.
 :: 9. set /a percentNum=%percent%:  Преобразует строковое значение percent в числовое значение percentNum.
 :: 10. if %percentNum% geq 95 ...:  Проверяет, превышает ли процент заполненности 95%.
 :: 11. powershell -Command "...":  Если процент заполненности превышает 95%,  выполняет PowerShell-команду для удаления файлов.
 ::  * Get-ChildItem '%targetFolder%':  Получает список файлов в целевой папке.
 ::   * Sort-Object LastWriteTime:  Сортирует файлы по времени последнего изменения.
 ::   * Select-Object -First 10:  Выбирает первые 10 файлов (самые старые).
 ::   * Remove-Item -Force:  Удаляет выбранные файлы принудительно.
 ::
 :: 12. pause:  Останавливает выполнение скрипта, ожидая нажатия клавиши.
::

@echo off
chcp 65001 >nul

:: Укажите диск, который хотите проверить
set drive=C:
set targetFolder=C:\apps

:: Получите процент заполненности диска через PowerShell
for /f "usebackq" %%P in (`powershell -Command "Get-WmiObject Win32_LogicalDisk -Filter 'DeviceID=\"%drive%\"' | ForEach-Object { $used = ($_.Size - $_.FreeSpace); $percent = [math]::Round(($used / $_.Size) * 100, 0); Write-Output $percent }"`) do (
    set percent=%%P
)

:: Отладочная информация
echo Debug: Raw percent value is %percent%.

:: Проверяем, определено ли значение
if not defined percent (
    echo Error: Unable to get the disk usage percentage.
    pause
    exit /b
)

:: Удаляем все пробелы из переменной
set percent=%percent: =%

:: Выводим процент заполненности диска
echo Drive %drive% is filled up to %percent%%.

:: Проверяем, если заполненность превышает 95%
set /a percentNum=0
set /a percentNum=%percent%
echo Debug: Converted percent value is %percentNum%.

if %percentNum% geq 95 (
    echo Disk usage is above 95%. Deleting the oldest files in %targetFolder%...

    :: Удаляем самые старые файлы в целевой папке
    powershell -Command "Get-ChildItem '%targetFolder%' | Sort-Object LastWriteTime | Select-Object -First 10 | Remove-Item -Force"

    echo Oldest files deleted.
) else (
    echo Disk usage is below 95%. No files will be deleted.
)

pause
