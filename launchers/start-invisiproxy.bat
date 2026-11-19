@echo off
rem InvisiProxy one-click launcher (Windows)
rem Double-click this file. It starts the local InvisiProxy LTS server,
rem waits for it, then opens Firefox at http://localhost:8080

setlocal EnableExtensions
title InvisiProxy launcher

set "SCRIPT_DIR=%~dp0"
if defined INVISIPROXY_DIR (set "ROOT=%INVISIPROXY_DIR%") else (set "ROOT=%SCRIPT_DIR%")
if not exist "%ROOT%package.json" set "ROOT=%SCRIPT_DIR%.."

cd /d "%ROOT%" 2>nul
if errorlevel 1 goto nofolder
if not exist "ecosystem.config.js" goto norepo

echo [InvisiProxy] Folder: %CD%

where node >nul 2>nul
if errorlevel 1 goto nonode

set "PORT="
for /f "tokens=2 delims=:" %%A in ('findstr /r /c:"PORT: [0-9]" ecosystem.config.js') do call :setport %%A
if not defined PORT set "PORT=8080"
set "URL=http://localhost:%PORT%"

where curl >nul 2>nul
if errorlevel 1 goto nocrl

curl -fsS --max-time 2 -o NUL "%URL%/manifest.json" >nul 2>nul
if not errorlevel 1 goto already

if exist "node_modules" if exist "lib\rammerhead\node_modules" goto startserver
echo [InvisiProxy] First run: installing dependencies (this takes a few minutes)...
call npm run fresh-install
if errorlevel 1 goto installfail

:startserver
echo [InvisiProxy] Starting server on port %PORT%...
call npm start
if errorlevel 1 goto startfail

echo [InvisiProxy] Waiting for the server to come up...
set /a COUNT=0
:waitloop
curl -fsS --max-time 2 -o NUL "%URL%/manifest.json" >nul 2>nul
if not errorlevel 1 goto ready
set /a COUNT+=1
if %COUNT% GEQ 120 goto timedout
timeout /t 1 /nobreak >nul
goto waitloop

:already
echo [InvisiProxy] Server already running at %URL% - opening Firefox.
goto open

:ready
echo [InvisiProxy] Ready at %URL% - opening Firefox.
goto open

:open
where firefox >nul 2>nul
if errorlevel 1 (start "" "%URL%") else (start "" firefox "%URL%")
timeout /t 2 /nobreak >nul
exit /b 0

:timedout
echo [InvisiProxy] The server did not answer within 2 minutes.
echo [InvisiProxy] Check the log with: npx pm2 logs InvisiProxyLTS
echo [InvisiProxy] Then open %URL% manually.
pause
exit /b 1

:nofolder
echo [InvisiProxy] Cannot enter the InvisiProxy folder: %ROOT%
pause
exit /b 1

:norepo
echo [InvisiProxy] This is not the InvisiProxy repo (no ecosystem.config.js in %CD%).
echo [InvisiProxy] Put this .bat file in the InvisiProxy folder and run it again.
pause
exit /b 1

:nonode
echo [InvisiProxy] Node.js is not installed.
echo [InvisiProxy] Install the LTS build from https://nodejs.org/ then run this again.
pause
exit /b 1

:nocrl
echo [InvisiProxy] curl.exe is missing. Install it or update Windows 10/11, then retry.
pause
exit /b 1

:installfail
echo [InvisiProxy] Dependency install failed. See the output above.
pause
exit /b 1

:startfail
echo [InvisiProxy] Server start failed. Run "npm run manual-start" in this folder to see the error.
pause
exit /b 1

:setport
set "PORT=%1"
set "PORT=%PORT: =%"
set "PORT=%PORT:,=%"
exit /b 0
