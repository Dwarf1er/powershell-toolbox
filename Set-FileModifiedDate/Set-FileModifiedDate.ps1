param (
    [string]$Directory = ".",
    [datetime]$Date = (Get-Date),
    [string[]]$Files,
    [switch]$Help
)

function Update-Set-FileModifiedDate {
    param (
        [string]$FilePath,
        [datetime]$Timestamp
    )
    if (Test-Path $FilePath) {
        Set-ItemProperty -Path $FilePath -Name LastWriteTime -Value $Timestamp
        Write-Host "Updated: $FilePath to $Timestamp"
    } else {
        Write-Host "File not found: $FilePath"
    }
}

function Show-Help {
    $helpMessage = @"
Usage: Set-FileModifiedDate [options]

Options:
    -Directory   <string>    Specify the directory to update timestamps for all files within. You must specify either a directory or specific file paths, but not both. Defaults to current directory if not provided.
    -Files       <string[]>  Specify one or more specific file paths to update their timestamps. You must specify either a directory or specific file paths, but not both.
    -Date        <datetime>  Specify the timestamp to set. Defaults to the current date and time if not provided.
    -Recurse     <switch>    Include this flag to recurse into subdirectories of the specified directory. This option is only used when updating timestamps for files in a directory.
    -Help        <swtich>    Display this help message.

Examples:
    Set-FileModifiedDate -Directory "C:\Path\To\Directory" -Recurse -Date "2025-01-01"
    Set-FileModifiedDate -Files "C:\Path\To\File1.txt", "C:\Path\To\File2.txt" -Date "2025-01-01"
    Set-FileModifiedDate -Directory "C:\Path\To\Directory" -Date "2025-01-01"
    Set-FileModifiedDate -Files "C:\Path\To\File1.txt" -Date "2025-01-01"
    
Notes:
    - You cannot specify both a directory and specific files at the same time.
    - The script updates the LastWriteTime property of the specified files or all files in a directory to the provided timestamp.
"@
    Write-Output $helpMessage
}

if ($Help) {
    Show-Help
    exit 0
}

if ($Directory -and $Files) {
    Write-Host "You cannot specify both a directory and specific files. Please provide one or the other."
    Show-Help
}

if (-not $Directory -and -not $Files) {
    Write-Host "You must specify either a directory or specific file paths."
    Show-Help
}

if ($Files) {
    foreach ($file in $Files) {
        Update-Set-FileModifiedDate -FilePath $file -Timestamp $Date
    }
}
else {
    if (-not (Test-Path $Directory)) {
        Write-Host "The specified directory does not exist."
        exit 1
    }

    (Get-ChildItem -Path $Directory -Recurse | Select-Object -ExpandProperty FullName) | ForEach-Object { Update-Set-FileModifiedDate -FilePath $_ -Timestamp $Date }
}
