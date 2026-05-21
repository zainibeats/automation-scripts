# rename-files-from-list.ps1
# Purpose: Batch rename files using names from a text file
# The script preserves file extensions and can ignore metadata after commas in the names list

# Configuration paths
# Format of names.txt: one entry per line as "Name,optional_metadata"
# Everything after the comma is ignored when renaming
$namesFilePath = "C:\Path\To\names.txt"

# Directory containing files to be renamed
# Files will be matched to names in alphabetical order
$targetFolderPath = "C:\Path\To\Files"

# Optional: Set the file type filter (e.g., "*.gif", "*.jpg", "*.*" for all files)
$fileFilter = "*.*"

# Extract names from the text file
# Split each line at comma and trim whitespace from the name portion
$names = Get-Content $namesFilePath | ForEach-Object {
    ($_ -split ",")[0].Trim()
}

# Get files sorted alphabetically to ensure consistent ordering
# This ordering will match the sequence of names in the text file
$files = Get-ChildItem -Path $targetFolderPath -Filter $fileFilter | Sort-Object Name

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
