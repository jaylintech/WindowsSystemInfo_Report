@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  SystemInfo_Report.bat
::  Gathers: Recent KB Updates, Network Drives, Printers
::  Compatible with Windows 11 (Standard User - No Admin Needed)
:: ============================================================

set "REPORT=%USERPROFILE%\Desktop\SystemInfo_Report.txt"

echo ============================================================ > "%REPORT%"
echo  SYSTEM INFORMATION REPORT >> "%REPORT%"
echo  Generated: %DATE% %TIME% >> "%REPORT%"
echo  User: %USERNAME% >> "%REPORT%"
echo  Computer: %COMPUTERNAME% >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"


:: ------------------------------------------------------------
:: 1. RECENTLY INSTALLED KB UPDATES
:: ------------------------------------------------------------
echo [1/3] Collecting KB Updates...

echo ============================================================ >> "%REPORT%"
echo  RECENTLY INSTALLED KB UPDATES >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"

:: Use wmic to list hotfixes (works without admin)
wmic qfe get HotFixID,Description,InstalledOn,InstalledBy /format:csv 2>nul | findstr /v "^$" | findstr /v "Node," > "%TEMP%\kb_raw.txt"

if %ERRORLEVEL% NEQ 0 (
    echo  [!] WMIC query failed. Trying PowerShell fallback... >> "%REPORT%"
    powershell -NoProfile -Command "Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID, Description, InstalledOn, InstalledBy | Format-Table -AutoSize" >> "%REPORT%" 2>nul
) else (
    :: Parse CSV output into readable format
    powershell -NoProfile -Command ^
        "Get-HotFix | Sort-Object InstalledOn -Descending | Format-Table -AutoSize -Property HotFixID, Description, InstalledOn, InstalledBy | Out-String -Width 200" >> "%REPORT%" 2>nul
)

del "%TEMP%\kb_raw.txt" 2>nul
echo. >> "%REPORT%"


:: ------------------------------------------------------------
:: 2. NETWORK DRIVES
:: ------------------------------------------------------------
echo [2/3] Collecting Network Drives...

echo ============================================================ >> "%REPORT%"
echo  MAPPED NETWORK DRIVES >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"

:: Method 1: net use (most reliable for standard users)
echo  --- Active Mapped Drives (net use) --- >> "%REPORT%"
net use >> "%REPORT%" 2>nul
echo. >> "%REPORT%"

:: Method 2: Registry-based persistent drives
echo  --- Persistent Mapped Drives (Registry) --- >> "%REPORT%"
reg query "HKCU\Network" /s 2>nul | findstr /i "HKEY RemotePath UserName" >> "%REPORT%"
if %ERRORLEVEL% NEQ 0 (
    echo  No persistent network drives found in registry. >> "%REPORT%"
)
echo. >> "%REPORT%"

:: Method 3: PowerShell for additional detail
echo  --- Drive Details (PowerShell) --- >> "%REPORT%"
powershell -NoProfile -Command ^
    "Get-PSDrive -PSProvider FileSystem | Where-Object {$_.DisplayRoot -like '\\*'} | Format-Table -AutoSize Name, Root, DisplayRoot, Description | Out-String -Width 200" >> "%REPORT%" 2>nul
echo. >> "%REPORT%"


:: ------------------------------------------------------------
:: 3. INSTALLED PRINTERS
:: ------------------------------------------------------------
echo [3/3] Collecting Installed Printers...

echo ============================================================ >> "%REPORT%"
echo  INSTALLED PRINTERS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"

:: Method 1: PowerShell Get-Printer (works for standard users)
echo  --- Printer List --- >> "%REPORT%"
powershell -NoProfile -Command ^
    "Get-Printer | Sort-Object Name | Format-Table -AutoSize Name, DriverName, PortName, Shared, PrinterStatus, Type | Out-String -Width 300" >> "%REPORT%" 2>nul

if %ERRORLEVEL% NEQ 0 (
    echo  [!] PowerShell Get-Printer failed. Trying wmic fallback... >> "%REPORT%"
    wmic printer get Name,DriverName,PortName,Network,Default /format:list >> "%REPORT%" 2>nul
)

:: Method 2: Default printer
echo. >> "%REPORT%"
echo  --- Default Printer --- >> "%REPORT%"
powershell -NoProfile -Command ^
    "Get-Printer | Where-Object {$_.Default -eq $true} | Select-Object Name, DriverName, PortName | Format-List | Out-String" >> "%REPORT%" 2>nul

echo. >> "%REPORT%"


:: ------------------------------------------------------------
:: DONE
:: ------------------------------------------------------------
echo ============================================================ >> "%REPORT%"
echo  END OF REPORT >> "%REPORT%"
echo ============================================================ >> "%REPORT%"

echo.
echo  [DONE] Report saved to:
echo  %REPORT%
echo.
echo  Opening report...
timeout /t 2 /nobreak >nul
start notepad "%REPORT%"

endlocal
