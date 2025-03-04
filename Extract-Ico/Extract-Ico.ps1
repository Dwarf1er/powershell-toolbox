param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Destination,

    [switch]$Help
)

function Show-Help {
    Write-Output "Usage: Extract-Ico -Path <PathToFile> -Destination <DestinationDirectory> [-Help]"
    Write-Output ""
    Write-Output "Parameters:"
    Write-Output "  -Path        : The path to the file from which to extract the icon. (Mandatory)"
    Write-Output "  -Destination : The directory where the extracted icon will be saved. (Mandatory)"
    Write-Output "  -Help        : Displays this help message."
    Write-Output ""
    Write-Output "Example:"
    Write-Output "  Extract-Ico -Path 'C:\Path\To\File.exe' -Destination 'C:\Path\To\Destination'"
}

if ($Help) {
    Show-Help
    exit 0
}

Add-Type -AssemblyName System.Drawing

if (-Not (Test-Path -Path $Path)) {
    Write-Error "The specified path '$Path' does not exist."
    exit 1
}

if (-Not (Test-Path -Path (Split-Path -Path $Destination -Parent))) {
    Write-Error "The specified destination directory does not exist."
    exit 1
}

function ConvertTo-Icon {
    param(
        [Parameter(Mandatory = $true)]
        [System.Drawing.Bitmap]$Bitmap,
        [string]$IconPath
    )

    $icon = [System.Drawing.Icon]::FromHandle($Bitmap.GetHicon())
    $fileStream = New-Object System.IO.FileStream($IconPath, 'OpenOrCreate')
    $icon.Save($fileStream)
    $fileStream.Close()
    $icon.Dispose()
}

$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Path)
$bitmap = $icon.ToBitmap()
$icoFilePath = Join-Path -Path $Destination -ChildPath "extracted_icon.ico"
ConvertTo-Icon -Bitmap $bitmap -IconPath $icoFilePath
$bitmap.Dispose()
Write-Output "Icon extracted and saved to '$icoFilePath'."
