@echo off
:: ========================================================
:: Piriform Domain Blocker (Hosts File Modifier)
:: Author: Goofyah
:: License: MIT (Free for open-use, modify responsibly)
:: Purpose: Blocks/unblocks Piriform/Avast domains via hosts file
:: ========================================================

:: Admin check and self-elevate
fltmc >nul 2>&1 || (
    echo [!] Requesting admin rights...
    set "args=%*"
    set "args=%args:"=%"
    echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~dp0"" && ""%~0"" %args%", "", "runas", 1 > "%temp%\admin.vbs"
    "%temp%\admin.vbs"
    del "%temp%\admin.vbs" >nul 2>&1
    exit /b
)

:: Configuration
set "hosts=%SystemRoot%\System32\drivers\etc\hosts"
set "log=%~dp0pblocker.log"
set "header=# Piriform/Avast Domain Blocker (Last Modified: %date% %time%)"

:: Domain List (Update as needed)
set "domains=license.piriform.com www.license.piriform.com speccy.piriform.com www.speccy.piriform.com recuva.piriform.com www.recuva.piriform.com defraggler.piriform.com www.defraggler.piriform.com ccleaner.piriform.com www.ccleaner.piriform.com license-api.ccleaner.com"

:: Functions
:log
    echo [%date% %time%] %* >> "%log%"
    goto :eof

:block
    echo [*] Blocking Piriform domains...
    call :log "Starting domain block..."
    
    takeown /f "%hosts%" /a >nul 2>&1 || (call :log "Failed to take ownership" && exit /b 1)
    icacls "%hosts%" /grant administrators:F >nul 2>&1 || (call :log "Failed to set permissions" && exit /b 1)
    attrib -h -r -s "%hosts%" >nul 2>&1 || (call :log "Failed to unhide hosts file" && exit /b 1)
    
    :: Add header if missing
    find /i "%header%" "%hosts%" >nul 2>&1 || echo %header% >> "%hosts%"
    
    :: Add domains
    for %%D in (%domains%) do (
        find /i "%%D" "%hosts%" >nul 2>&1 || (
            echo 127.0.0.1                   %%D >> "%hosts%"
            call :log "Added: %%D"
        )
    )
    
    attrib +h +r +s "%hosts%" >nul 2>&1
    call :log "Blocking completed."
    echo [+] Done. Domains blocked. Log: %log%
    goto :eof

:unblock
    echo [*] Unblocking Piriform domains...
    call :log "Starting domain unblock..."
    
    takeown /f "%hosts%" /a >nul 2>&1 || (call :log "Failed to take ownership" && exit /b 1)
    icacls "%hosts%" /grant administrators:F >nul 2>&1 || (call :log "Failed to set permissions" && exit /b 1)
    attrib -h -r -s "%hosts%" >nul 2>&1 || (call :log "Failed to unhide hosts file" && exit /b 1)
    
    :: Remove domains and header
    type "%hosts%" | findstr /v /i "%header%" | findstr /v /i "127.0.0.1 %domains: = 127.0.0.1 %" > "%hosts%.tmp"
    move /y "%hosts%.tmp" "%hosts%" >nul 2>&1
    
    attrib +h +r +s "%hosts%" >nul 2>&1
    call :log "Unblocking completed."
    echo [+] Done. Domains unblocked. Log: %log%
    goto :eof

:: Main Menu
echo.
echo [ Piriform Domain Blocker ]
echo --------------------------
echo 1. Block Domains (Stop Piriform/Avast calls)
echo 2. Unblock Domains (Restore original hosts file)
echo 3. Exit
echo.

choice /c 123 /n /m "Select option (1-3): "
if %errorlevel% equ 1 call :block
if %errorlevel% equ 2 call :unblock
if %errorlevel% equ 3 exit /b

pause >nul
