[CmdletBinding()]
param(
    [string]$CustomizationDirectory,
    [string]$InstallDirectory = (Join-Path $env:USERPROFILE "Documents\H871-Tools\PartFilter"),
    [switch]$Force
)
$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot "..\..\.."))
$coreSource = Join-Path $repoRoot "src\part-filter\ver-03\H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp"
$iconGenerator = Join-Path $repoRoot "src\h871-ribbon\tools\Generate-H871Icon.ps1"
$commandTemplate = Join-Path $repoRoot "src\h871-ribbon\H871_AVAILABLE_COMMANDS_SNIPPET.cmd"
foreach ($file in @($coreSource, $iconGenerator, $commandTemplate)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw ("Required package file is missing: " + $file + ". Extract the complete repository ZIP.")
    }
}
if ([string]::IsNullOrWhiteSpace($CustomizationDirectory)) {
    Write-Host "Enter the personal Modeling customization directory (do not use a guessed factory path)."
    $CustomizationDirectory = Read-Host "Customization directory"
}
if (-not (Test-Path -LiteralPath $CustomizationDirectory -PathType Container)) {
    throw "Customization directory does not exist. No files were installed."
}
$CustomizationDirectory = (Resolve-Path -LiteralPath $CustomizationDirectory).Path
$InstallDirectory = [System.IO.Path]::GetFullPath($InstallDirectory)
New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
$backupRoot = Join-Path $InstallDirectory ("backup\" + (Get-Date -Format "yyyyMMdd-HHmmss"))
$backupCreated = $false
function Backup-IfPresent {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        if (-not $script:Force) {
            throw ("Target already exists: " + $Path + ". Use -Force to replace it; existing files are never replaced without backup.")
        }
        if (-not $script:backupCreated) {
            New-Item -ItemType Directory -Path $script:backupRoot -Force | Out-Null
            $script:backupCreated = $true
        }
        $name = [System.IO.Path]::GetFileName($Path)
        $destination = Join-Path $script:backupRoot $name
        $index = 1
        while (Test-Path -LiteralPath $destination) {
            $destination = Join-Path $script:backupRoot ("{0}.{1}" -f $name, $index)
            $index++
        }
        Copy-Item -LiteralPath $Path -Destination $destination
        Write-Host ("BACKUP: " + $Path + " -> " + $destination)
    }
}
$coreTarget = Join-Path $InstallDirectory "H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp"
$commandTarget = Join-Path $InstallDirectory "H871_AVAILABLE_COMMANDS_SNIPPET.cmd"
$iconTarget = Join-Path $CustomizationDirectory "bitmaps\bmp\commands\H871\part_filter.bmp"
# Preflight all overwrite conditions before changing any target.
Backup-IfPresent -Path $coreTarget
Backup-IfPresent -Path $commandTarget
Backup-IfPresent -Path $iconTarget
Copy-Item -LiteralPath $coreSource -Destination $coreTarget -Force
Copy-Item -LiteralPath $commandTemplate -Destination $commandTarget -Force
Write-Host ("Installed Lisp core: " + $coreTarget)
Write-Host ("Installed command reference: " + $commandTarget)
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $iconGenerator -CustomizationDirectory $CustomizationDirectory
if ($LASTEXITCODE -ne 0) {
    throw ("Icon generation failed with exit code " + $LASTEXITCODE + ". Review the error and rerun after correction.")
}
$loadCommand = '(load "' + ($coreTarget -replace '\\','/') + '")'
$loadFile = Join-Path $InstallDirectory "LOAD_H871_PART_FILTER.txt"
@(
    "In Creo Elements/Direct Modeling 18.1, execute this Lisp expression in the command/input line:",
    "",
    $loadCommand,
    "",
    "The core must be loaded in each new Modeling session until startup loading is separately configured."
) | Set-Content -LiteralPath $loadFile -Encoding UTF8
Write-Host ""
Write-Host "H871 installation files are ready."
Write-Host ("Lisp:       " + $coreTarget)
Write-Host ("Icon:       " + $iconTarget)
Write-Host ("Command:    " + $commandTarget)
Write-Host ("Load guide: " + $loadFile)
if ($backupCreated) { Write-Host ("Backup:     " + $backupRoot) }
Write-Host ""
Write-Host "NEXT: Load the Lisp, register the user-defined command through Customize / Commands,"
Write-Host "then add that saved command to your custom Ribbon group. See README_INSTALL.txt."
