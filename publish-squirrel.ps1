param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Runtime = "win-x64",
    [string]$SquirrelPath = "C:\Tools\Squirrel\tools\Squirrel.exe",
    [string]$SetupExeName = "Setup.exe"
)

$ErrorActionPreference = "Stop"

$projectPath = "C:\Users\Admin\source\repos\Soporte Modelos\Soporte Modelos\Soporte Modelos.csproj"
$publishDir = Join-Path $PSScriptRoot "publish"

if (-not $projectPath -or -not (Test-Path -LiteralPath $projectPath)) {
    $projectPath = Read-Host "No se encontró el .csproj. Ingresa la ruta completa del .csproj"
}

if (-not $projectPath -or -not (Test-Path -LiteralPath $projectPath)) {
    throw "No se encontró el proyecto (.csproj)."
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "dotnet no está disponible en PATH"
}


function Resolve-SquirrelPath {
    param([string]$PreferredPath)

    if ($PreferredPath -and (Test-Path -LiteralPath $PreferredPath)) {
        return $PreferredPath
    }

    $command = Get-Command Squirrel -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $nugetRoot = Join-Path $env:USERPROFILE ".nuget\packages"
    if (Test-Path -LiteralPath $nugetRoot) {
        $candidate = Get-ChildItem -LiteralPath $nugetRoot -Recurse -Filter "Squirrel.exe" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match "clowd\.squirrel" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    return $null
}

$resolvedSquirrelPath = Resolve-SquirrelPath -PreferredPath $SquirrelPath
if (-not $resolvedSquirrelPath) {
    throw "Squirrel.exe no está disponible. Instala Clowd.Squirrel y asegúrate de tener Squirrel.exe accesible."
}

Write-Host "Publicando en $publishDir"

dotnet publish $projectPath -c Release -r $Runtime -o $publishDir

Write-Host "Generando paquete NuGet para Squirrel"

$packRoot = Join-Path $publishDir "pack"
if (Test-Path -LiteralPath $packRoot) {
    Remove-Item -LiteralPath $packRoot -Recurse -Force
}

$libDir = Join-Path $packRoot "lib\net10.0-windows"
New-Item -ItemType Directory -Path $libDir -Force | Out-Null

$publishItems = Get-ChildItem -LiteralPath $publishDir | Where-Object {
    $_.Name -notin @("Releases", "pack") -and $_.Extension -ne ".nupkg"
}

foreach ($item in $publishItems) {
    Copy-Item -LiteralPath $item.FullName -Destination $libDir -Recurse -Force
}

$nuspecPath = Join-Path $packRoot "SoporteModelos.nuspec"
$nuspecContent = @"
<?xml version="1.0"?>
<package>
  <metadata>
    <id>SoporteModelos</id>
    <version>$Version</version>
    <authors>SoporteModelos</authors>
    <description>Soporte Modelos</description>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
  </metadata>
</package>
"@

Set-Content -LiteralPath $nuspecPath -Value $nuspecContent -Encoding UTF8


$tempZipPath = Join-Path $publishDir "SoporteModelos.$Version.zip"
$nupkgPath = Join-Path $publishDir "SoporteModelos.$Version.nupkg"
if (Test-Path -LiteralPath $tempZipPath) {
    Remove-Item -LiteralPath $tempZipPath -Force
}
if (Test-Path -LiteralPath $nupkgPath) {
    Remove-Item -LiteralPath $nupkgPath -Force
}

Compress-Archive -Path (Join-Path $packRoot "*") -DestinationPath $tempZipPath
Rename-Item -LiteralPath $tempZipPath -NewName (Split-Path -Leaf $nupkgPath)

if (-not (Test-Path -LiteralPath $nupkgPath)) {
    throw "No se encontró el .nupkg en $publishDir"
}

Write-Host "Generando Releases de Squirrel"

& $resolvedSquirrelPath --releasify $nupkgPath --releaseDir (Join-Path $publishDir "Releases") --setupExe $SetupExeName

Write-Host "Listo. Archivos en: $(Join-Path $publishDir "Releases")"
