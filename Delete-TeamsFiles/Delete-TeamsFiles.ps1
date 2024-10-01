$OneDrivePath = "$env:OneDrive"
$FolderName = "Microsoft Teams Chat Files"
$FullFolderPath = Join-Path -Path $OneDrivePath -ChildPath $FolderName

if(Test-Path $FullFolderPath) {
    Remove-Item -Path $FullFolderPath -Recurse -Force
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $OneDrivePath
$watcher.Filter = $FolderName
$watcher.IncludeSubdirectories = $false
$watcher.NotifyFilter = [System.IO.NotifyFilter]"Directoryname"

$action = {
    param($source, $e)
    if ($e.ChangeType -eq [System.IO.WatcherChangeTypes]::Created) {
        Start-Sleep -Seconds 1
        if(Test-Path $e.FullPath) {
            try {
                Remove-Item -Path $e.FullPath -Recurse -Force
                Write-Output "Deleted folder: $($e.FullPath)"
            } catch {
                Write-Output "Error deleting folder: $_"
            }
        }
    }
}

Unregister-Event -SourceIdentifier "FileSystemWatcher" -ErrorAction SilentlyContinue
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -SourceIdentifier "FileSystemWatcher"

$watcher.EnableRaisingEvents = $true

Write-Output "Monitoring for the creating of '$FullFolderPath'. Press [Ctrl + C] to exit."
while($true) {
    Start-Sleep -Seconds 1
}

Unregister-Event -SourceIdentifier "FileSystemWatcher" -ErrorAction SilentlyContinue
$watcher.Dispose()