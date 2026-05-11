param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Runtime = "win-x64",
    [string]$SquirrelPath = "",
    [string]$SetupExeName = "SoporteModelosSetup.exe"
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

    if ($PreferredPath -and (Test-Path -LiteralPath $PreferredPath)) {
        return $PreferredPath
    }

    $command = Get-Command Squirrel -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    return $null
}

$resolvedSquirrelPath = Resolve-SquirrelPath -PreferredPath $SquirrelPath
if (-not $resolvedSquirrelPath) {
    throw "Squirrel.exe no está disponible. Instala Clowd.Squirrel y asegúrate de tener Squirrel.exe accesible."
}

Write-Host "Publicando en $publishDir"

dotnet publish $projectPath -c Release -r $Runtime -o $publishDir

Write-Host "Preparando carpeta para Squirrel"

$packRoot = Join-Path $publishDir "pack"
$packDir = Join-Path $packRoot "app"
if (Test-Path -LiteralPath $packRoot) {
    Remove-Item -LiteralPath $packRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $packDir -Force | Out-Null

$publishItems = Get-ChildItem -LiteralPath $publishDir | Where-Object {
    $_.Name -notin @("Releases", "pack") -and $_.Extension -ne ".nupkg"
}

foreach ($item in $publishItems) {
    Copy-Item -LiteralPath $item.FullName -Destination $packDir -Recurse -Force
}

Write-Host "Generando Releases de Squirrel"

& $resolvedSquirrelPath pack --releaseDir (Join-Path $publishDir "Releases") --packId SoporteModelos --packVersion $Version --packDir $packDir --allowUnaware

$releaseDir = Join-Path $publishDir "Releases"
$releasesFile = Join-Path $releaseDir "RELEASES"
$setupExePath = Join-Path $releaseDir $SetupExeName
$fullPackage = Get-ChildItem -LiteralPath $releaseDir -Filter "*-full.nupkg" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not (Test-Path -LiteralPath $releasesFile) -or -not (Test-Path -LiteralPath $setupExePath) -or -not $fullPackage) {
    $existing = if (Test-Path -LiteralPath $releaseDir) { (Get-ChildItem -LiteralPath $releaseDir | Select-Object -ExpandProperty Name) -join ", " } else { "(sin carpeta Releases)" }
    throw "No se generaron todos los archivos esperados (RELEASES, Setup.exe, *-full.nupkg). Archivos encontrados: $existing"
}

Write-Host "Listo. Archivos en: $(Join-Path $publishDir "Releases")"
