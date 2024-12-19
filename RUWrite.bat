@echo off
chcp 65001 >nul

title Подготовка загрузочной флешки

:input
echo Пожалуйста, введите букву диска (например, E) и нажмите Enter:
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

REM Создаем скрипт для Diskpart
(
echo select volume %driveLetter%
echo clean
echo create partition primary
echo select partition 1
echo active
echo format fs=ntfs quick
echo assign letter=%driveLetter%
echo exit
) > diskpart_script.txt

REM Выполняем скрипт Diskpart
diskpart /s diskpart_script.txt

if %errorlevel% neq 0 (
    echo Ошибка при форматировании диска.
    pause
    goto end
)

del diskpart_script.txt

echo Монтирование ISO файла %isoPath%:
PowerShell Mount-DiskImage -ImagePath "%isoPath%" -PassThru | PowerShell Get-Volume -FileSystemLabel "CD-ROM" | ForEach-Object { $_.DriveLetter } > tmpDriveLetter.txt
set /p isoDriveLetter=<tmpDriveLetter.txt
del tmpDriveLetter.txt

if "%isoDriveLetter%"=="" (
    echo Ошибка при монтировании ISO файла.
    pause
    goto end
)

echo Копирование файлов с ISO на флешку %driveLetter%:
xcopy /e /h /k /o /x "%isoDriveLetter%:\*" "%driveLetter%:\"

echo Размонтирование ISO файла:
PowerShell Dismount-DiskImage -ImagePath "%isoPath%"

echo Процесс завершен.
pause
goto end

:end
echo Операция отменена.
pause
