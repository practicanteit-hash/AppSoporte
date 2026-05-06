param(
    [string]$CredentialJsonPath = (Join-Path $PSScriptRoot "credenciales.json"),
    [string]$AppPath
)

if (-not $AppPath) {
    $AppPath = Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.exe" -File | Select-Object -First 1 -ExpandProperty FullName
}

if (-not (Test-Path -LiteralPath $CredentialJsonPath)) {
    Write-Host "No se encontró el archivo de credenciales en: $CredentialJsonPath"
    Write-Host "Coloca el archivo en esa ubicación. Esperando hasta 10 segundos..."
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        if (Test-Path -LiteralPath $CredentialJsonPath) { break }
    }
}

if (-not (Test-Path -LiteralPath $CredentialJsonPath)) {
    throw "No se encontró el archivo de credenciales: $CredentialJsonPath"
}

if (-not $AppPath -or -not (Test-Path -LiteralPath $AppPath)) {
    throw "No se encontró la app en la carpeta: $PSScriptRoot"
}

$env:GOOGLE_SHEETS_CREDENTIALS_JSON = Get-Content -Raw -LiteralPath $CredentialJsonPath
Start-Process -FilePath $AppPath

