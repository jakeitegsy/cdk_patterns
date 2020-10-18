# Sniffer
param([String]$Folder, [String]$Command)
$path = $1

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $Folder
$watcher.Filter = "*.*"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $Command
}

Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action
while ($true) { sleep 5 }
