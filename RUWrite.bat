@echo off
chcp 65001 >nul

title Подготовка загрузочной флешки

:input
echo Пожалуйста, введите букву диска (например, G) и нажмите Enter:
set /p driveLetter=

echo Пожалуйста, введите путь к ISO файлу (например, C:\temp\test.iso) и нажмите Enter:
set /p isoPath=

echo Вы выбрали диск %driveLetter% и ISO файл %isoPath%.
echo !!! ВНИМАНИЕ: Все данные на этом диске будут удалены !!!
pause

echo Вы уверены, что хотите продолжить? Введите Y для продолжения или N для отмены.
choice /c YN /n /m "Подтвердите выбор: "
if errorlevel 2 goto end

echo Второе подтверждение! Все данные будут удалены с диска %driveLetter%.
echo Введите Y для окончательного подтверждения или N для отмены.
choice /c YN /n /m "Подтвердите выбор: "
if errorlevel 2 goto end

REM Выполнение команд Diskpart для форматирования в NTFS
echo select volume %driveLetter% > diskpart_script.txt
echo clean >> diskpart_script.txt
echo create partition primary >> diskpart_script.txt
echo select partition 1 >> diskpart_script.txt
echo active >> diskpart_script.txt
echo format fs=ntfs quick >> diskpart_script.txt
echo assign letter=%driveLetter% >> diskpart_script.txt
echo exit >> diskpart_script.txt

diskpart /s diskpart_script.txt
if errorlevel 1 (
    echo Ошибка при выполнении команд Diskpart. Попытка форматирования в FAT32...
    format %driveLetter%: /FS:FAT32 /Q /V:USB
)
del diskpart_script.txt

REM Монтирование ISO файла
echo Монтирование ISO файла...
PowerShell -Command "Mount-DiskImage -ImagePath '%isoPath%'"
if errorlevel 1 (
    echo Ошибка при монтировании ISO файла. Проверьте правильность пути к ISO файлу и доступность диска.
    pause
    goto end
)

REM Ожидание монтирования ISO файла
timeout /t 5

REM Получение буквы смонтированного ISO диска
for /f "tokens=2 delims=:" %%I in ('PowerShell -Command "Get-Volume | Where-Object { $_.DriveType -eq 'CD-ROM' } | Select-Object -ExpandProperty DriveLetter"') do set isoDriveLetter=%%I

if "%isoDriveLetter%"=="" (
    echo Не удалось определить букву смонтированного ISO диска.
    pause
    goto end
)

echo Буква смонтированного ISO диска: %isoDriveLetter%

REM Копирование файлов с ISO на флешку
echo Копирование файлов с ISO на флешку %driveLetter%:
xcopy /e /h /k /o /x "%isoDriveLetter%:\*" "%driveLetter%:\"

REM Размонтирование ISO файла
PowerShell -Command "Dismount-DiskImage -ImagePath '%isoPath%'"

echo Процесс завершен.
pause

:end
echo Операция завершена.
pause
