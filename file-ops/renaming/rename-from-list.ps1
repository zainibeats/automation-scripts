# rename-files-from-list.ps1
# Purpose: Batch rename files using names from a text file
# The script preserves file extensions and can ignore metadata after commas in the names list

param(
    [string]$NamesFilePath = $env:NAMES_FILE_PATH,
    [string]$TargetFolderPath = $env:TARGET_FOLDER_PATH,
    [string]$FileFilter = $(if ($env:FILE_FILTER) { $env:FILE_FILTER } else { "*.*" }),
    [switch]$Help
)

function Show-Usage {
    Write-Host @"
Usage: .\rename-from-list.ps1 -NamesFilePath PATH -TargetFolderPath PATH [-FileFilter FILTER]

Batch rename files using names from a text file.

Options:
  -NamesFilePath      Text file with one name per line. Text after a comma is ignored.
  -TargetFolderPath   Directory containing files to rename.
  -FileFilter         File filter, default: *.*
  -Help               Show this help message.

Configuration:
  Values can also be set in environment variables or in .env next to this script:
  NAMES_FILE_PATH, TARGET_FOLDER_PATH, FILE_FILTER
"@
}

function Import-DotEnv {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) {
            return
        }

        $key, $value = $line -split "=", 2
        $key = $key.Trim()
        $value = $value.Trim().Trim('"').Trim("'")

        if ($key) {
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-DotEnv -Path (Join-Path $scriptDir ".env")

if (-not $NamesFilePath) {
    $NamesFilePath = $env:NAMES_FILE_PATH
}
if (-not $TargetFolderPath) {
    $TargetFolderPath = $env:TARGET_FOLDER_PATH
}
if (-not $FileFilter) {
    $FileFilter = if ($env:FILE_FILTER) { $env:FILE_FILTER } else { "*.*" }
}

if ($Help) {
    Show-Usage
    exit 0
}

if (-not $NamesFilePath -or -not $TargetFolderPath) {
    Write-Error "NamesFilePath and TargetFolderPath are required."
    Show-Usage
    exit 1
}

if (-not (Test-Path -LiteralPath $NamesFilePath)) {
    Write-Error "Names file does not exist: $NamesFilePath"
    exit 1
}

if (-not (Test-Path -LiteralPath $TargetFolderPath -PathType Container)) {
    Write-Error "Target folder does not exist: $TargetFolderPath"
    exit 1
}

# Extract names from the text file.
# Split each line at comma and trim whitespace from the name portion
$names = Get-Content $NamesFilePath | ForEach-Object {
    ($_ -split ",")[0].Trim()
}

# Get files sorted alphabetically to ensure consistent ordering
# This ordering will match the sequence of names in the text file
$files = Get-ChildItem -Path $TargetFolderPath -Filter $FileFilter | Sort-Object Name

# Validate file count matches name count to prevent partial renaming
if ($files.Count -ne $names.Count) {
    Write-Error "Mismatch: There are $($files.Count) files but $($names.Count) names in the text file."
    exit
}

# Perform the renaming operation
# Loop through files and names simultaneously, preserving original extensions
for ($i = 0; $i -lt $files.Count; $i++) {
    # Construct new filename using the corresponding name from the list
    # and the original file extension
    $newName = "$($names[$i])$($files[$i].Extension)"
    
    # Rename the file using the new name
    Rename-Item -Path $files[$i].FullName -NewName $newName
}
