@echo off
set "version=%~1"
if "%version%"=="" (
  set /p version=Ingresa la version ^(ej 1.0.1^): 
)

if "%version%"=="" (
  echo Debes ingresar una version.
  exit /b 1
)

set "releaseDir=%~dp0publish\Releases"
if exist "%releaseDir%\*-%version%-full.nupkg" (
  echo La version %version% ya existe en %releaseDir%.
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0publish-squirrel.ps1" -Version %version%
