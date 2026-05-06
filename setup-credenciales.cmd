@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath '%APPDATA%\Soporte_Modelos\credenciales.bin' -Force -ErrorAction SilentlyContinue"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-credenciales.ps1" -CredentialJsonPath "%~1"
