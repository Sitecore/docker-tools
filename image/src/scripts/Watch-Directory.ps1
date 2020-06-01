[CmdletBinding()]
param(
    # Path to watch for changes
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [string]$Path,
    # Destination path to keep updated
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType 'Container' })]
    [string]$Destination,
    # Milliseconds to sleep between sync operations
    [Parameter(Mandatory = $false)]
    [int]$SleepMilliseconds = 200,
    # Default files to skip during sync
    [Parameter(Mandatory = $false)]
    [array]$DefaultExcludedFiles = @("*.user", "*.cs", "*.csproj", "packages.config", "*ncrunch*", ".gitignore", ".gitkeep", ".dockerignore", "*.example", "*.disabled"),
    # Additional files to skip during sync
    [Parameter(Mandatory = $false)]
    [array]$ExcludeFiles = @(),
    # Default directories to skip during sync
    [Parameter(Mandatory = $false)]
    [array]$DefaultExcludedDirectories = @("obj", "Properties", "node_modules"),
    # Additional directories to skip during sync
    [Parameter(Mandatory = $false)]
    [array]$ExcludeDirectories = @()
)

$timeFormat = "HH:mm:ss:fff"

function Sync
{
    param(
        [Parameter(Mandatory = $true)]
        $Path,
        [Parameter(Mandatory = $true)]
        $Destination,
        [Parameter(Mandatory = $false)]
        $ExcludeFiles,
        [Parameter(Mandatory = $false)]
        $ExcludeDirectories
    )

    $command = @("robocopy", "`"$Path`"", "`"$Destination`"", "/E", "/XX", "/MT:1", "/NJH", "/NJS", "/FP", "/NDL", "/NP", "/NS", "/R:5", "/W:1")

    if ($ExcludeDirectories.Count -gt 0)
    {
        $command += "/XD "

        $ExcludeDirectories | ForEach-Object {
            $command += "`"$_`" "
        }

        $command = $command.TrimEnd()
    }

    if ($ExcludeFiles.Count -gt 0)
    {
        $command += "/XF "

        $ExcludeFiles | ForEach-Object {
            $command += "`"$_`" "
        }

        $command = $command.TrimEnd()
    }

    $commandString = $command -join " "

    $dirty = $false
    $raw = &([scriptblock]::create($commandString))
    $raw | ForEach-Object {
        $line = $_.Trim().Replace("`r`n", "").Replace("`t", " ")
        $dirty = ![string]::IsNullOrEmpty($line)

        if ($dirty)
        {
            Write-Host "$(Get-Date -Format $timeFormat): $line" -ForegroundColor DarkGray
        }
    }

    if ($dirty)
    {
        Write-Host "$(Get-Date -Format $timeFormat): Done syncing..." -ForegroundColor Green
    }
}

# Setup exclude rules
$fileRules = ($DefaultExcludedFiles + $ExcludeFiles) | Select-Object -Unique
$directoryRules = ($DefaultExcludedDirectories + $ExcludeDirectories) | Select-Object -Unique

Write-Host "$(Get-Date -Format $timeFormat): Excluding files: $($fileRules -join ", ")"
Write-Host "$(Get-Date -Format $timeFormat): Excluding directories: $($directoryRules -join ", ")"

# Cleanup old event if present in current session
Get-EventSubscriber -SourceIdentifier "FileDeleted" -ErrorAction "SilentlyContinue" | Unregister-Event

# Setup delete watcher
$watcher = New-Object System.IO.FileSystemWatcher -Property @{
    Path = $Path
    IncludeSubdirectories = $true
    EnableRaisingEvents = $true
}

Register-ObjectEvent $watcher Deleted -SourceIdentifier "FileDeleted" -MessageData $Destination {
    $destinationPath = Join-Path $event.MessageData $eventArgs.Name
    $delete = !(Test-Path $eventArgs.FullPath) -and (Test-Path $destinationPath) -and !(Test-Path -Path $destinationPath -PathType "Container")

    if ($delete)
    {
        $retries = 5
        while ($retries -gt 0) 
        {
            try
            {
                Remove-Item -Path $destinationPath -Force -Recurse -ErrorAction Stop
                Write-Host "$(Get-Date -Format $timeFormat): Deleted '$destinationPath'..." -ForegroundColor Green

                $retries = -1
            }
            catch
            {
                $retries--
                Start-Sleep -Seconds 1
            }
        }
        if ($retries -eq 0) 
        {
            Write-Host "$(Get-Date -Format $timeFormat): Could not delete '$destinationPath'..." -ForegroundColor Red
        }
    }
} | Out-Null

try
{
    Write-Host "$(Get-Date -Format $timeFormat): Watching '$Path' for changes, will copy to '$Destination'..."

    # Main loop
    while ($true)
    {
        Sync -Path $Path -Destination $Destination -ExcludeFiles $fileRules -ExcludeDirectories $directoryRules

        Start-Sleep -Milliseconds $SleepMilliseconds
    }
}
finally
{
    # Cleanup
    Get-EventSubscriber -SourceIdentifier "FileDeleted" | Unregister-Event

    if ($null -ne $watcher)
    {
        $watcher.Dispose()
        $watcher = $null
    }

    Write-Host "$(Get-Date -Format $timeFormat): Stopped." -ForegroundColor Red
}