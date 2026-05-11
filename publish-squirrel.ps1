param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Runtime = "win-x64",
    [string]$SquirrelPath = "C:\Tools\Squirrel\tools\Squirrel.exe"
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

Write-Host "Generando paquete NuGet"

$env:NUGET_PACKAGES = Join-Path $PSScriptRoot "packages"

dotnet pack $projectPath -c Release -o $publishDir -p:PackageVersion=$Version

$nupkg = Get-ChildItem -LiteralPath $publishDir -Filter "*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $nupkg) {
    throw "No se encontró el .nupkg en $publishDir"
}

Write-Host "Generando Releases de Squirrel"

& $resolvedSquirrelPath --releasify $nupkg.FullName --releaseDir (Join-Path $publishDir "Releases")

Write-Host "Listo. Archivos en: $(Join-Path $publishDir "Releases")"
