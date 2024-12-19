@echo off

title Preparing Bootable USB Drive

:input
echo Please enter the drive letter (e.g., E) and press Enter:
set /p driveLetter=

echo Please enter the path to the ISO file (e.g., C:\temp\test.iso) and press Enter:
set /p isoPath=

echo You have selected drive %driveLetter% and ISO file %isoPath%.
echo !!! WARNING: All data on this drive will be erased !!!
pause

echo Are you sure you want to continue? Press Y to continue or N to cancel.
choice /c YN /n /m "Confirm your choice: "
if errorlevel 2 goto end

echo Second confirmation! All data will be erased from drive %driveLetter%.
echo Press Y for final confirmation or N to cancel.
choice /c YN /n /m "Confirm your choice: "
if errorlevel 2 goto end

REM Create Diskpart script
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

REM Execute Diskpart script
diskpart /s diskpart_script.txt

if %errorlevel% neq 0 (
    echo Error formatting the drive.
    pause
    goto end
)

del diskpart_script.txt

echo Mounting ISO file %isoPath%:
PowerShell Mount-DiskImage -ImagePath "%isoPath%" -PassThru | PowerShell Get-Volume -FileSystemLabel "CD-ROM" | ForEach-Object { $_.DriveLetter } > tmpDriveLetter.txt
set /p isoDriveLetter=<tmpDriveLetter.txt
del tmpDriveLetter.txt

if "%isoDriveLetter%"=="" (
    echo Error mounting the ISO file.
    pause
    goto end
)

echo Copying files from ISO to USB drive %driveLetter%:
xcopy /e /h /k /o /x "%isoDriveLetter%:\*" "%driveLetter%:\"

echo Dismounting ISO file:
PowerShell Dismount-DiskImage -ImagePath "%isoPath%"

echo Process completed.
pause
goto end

:end
echo Operation cancelled.
pause
