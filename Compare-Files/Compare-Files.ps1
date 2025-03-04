param(
    [switch]$Help,
    [string]$File1,
    [string]$File2
)

function Show-Help {
    $helpMessage = @"
Compare-Files - A simple file comparison tool like 'diff'

Usage:
  Compare-Files -File1 <file1> -File2 <file2>

Parameters:
  -File1    Path to the first file
  -File2    Path to the second file
  -Help     Show this help message
"@
    Write-Host $helpMessage
}

if ($Help) {
    Show-Help
    exit
}

if (-not $File1 -or -not $File2) {
    Write-Host "Error: Both '-File1' and '-File2' parameters are required."
    Show-Help
    exit
}

if (-not (Test-Path $File1)) {
    Write-Host "Error: '$File1' does not exist."
    Show-Help
    exit
}

if (-not (Test-Path $File2)) {
    Write-Host "Error: '$File2' does not exist."
    Show-Help
    exit
}

$File1Content = Get-Content $File1
$File2Content = Get-Content $File2

$differences = Compare-Object $File1Content $File2Content

if ($differences) {
    $differences | ForEach-Object {
        if ($_.SideIndicator -eq '=>') {
            Write-Host "File2: $($_.InputObject)"
        } elseif ($_.SideIndicator -eq '<=') {
            Write-Host "File1: $($_.InputObject)"
        }
    }
} else {
    Write-Host "The files are identical."
}
