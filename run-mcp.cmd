@echo off
setlocal EnableExtensions
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "CLI=%ROOT%\dist\yaaif-cursor-mcp.mjs"
set "BUNDLED=%ROOT%\runtime\node\node.exe"

if exist "%BUNDLED%" (
  set "NODE_BIN=%BUNDLED%"
  goto :run
)

where node >nul 2>&1
if errorlevel 1 goto :fail

node -e "process.exit(Number(process.versions.node.split('.')[0])>=20?0:1)" >nul 2>&1
if errorlevel 1 goto :fail
set "NODE_BIN=node"
goto :run

:fail
echo YAAIF Cursor plugin: Node.js ^>= 20 not found. Re-run the YAAIF Cursor plugin installer or install Node 20+. 1>&2
exit /b 1

:run
if not exist "%CLI%" (
  echo Missing %CLI% — build packages\mcp first. 1>&2
  exit /b 1
)
"%NODE_BIN%" "%CLI%" --client cursor %*
exit /b %ERRORLEVEL%
