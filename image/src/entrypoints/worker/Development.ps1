[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [hashtable]$WatchDirectoryParameters
)

# setup
$ErrorActionPreference = "STOP"

$timeFormat = "HH:mm:ss:fff"

# print start message
Write-Host "$(Get-Date -Format $timeFormat): Development ENTRYPOINT, starting..."

# check to see if we should start the Watch-Directory.ps1 script
$watchDirectoryJobName = "Watch-Directory.ps1"
$useWatchDirectory = $null -ne $WatchDirectoryParameters -bor (Test-Path -Path "C:\deploy" -PathType "Container") -eq $true

if ($useWatchDirectory)
{
    # setup default parameters if none is supplied
    if ($null -eq $WatchDirectoryParameters)
    {
        $WatchDirectoryParameters = @{ Path = "C:\deploy"; Destination = "C:\service"; }
    }

    # start Watch-Directory.ps1 in background
    $job = Start-Job -Name $watchDirectoryJobName -ArgumentList $WatchDirectoryParameters -ScriptBlock {
        param([hashtable]$params)

        & "C:\tools\scripts\Watch-Directory.ps1" @params

    }

    # wait to see if job failed (it will if for example parsing in invalid parameters)...
    Start-Sleep -Seconds 1

    # writes output stream
    $job | Receive-Job

    if ($job.State -ne "Running")
    {
        # exit
        exit 1
    }

    Write-Host "$(Get-Date -Format $timeFormat): Job '$watchDirectoryJobName' started."
}
else
{
    Write-Host ("$(Get-Date -Format $timeFormat): Skipping start of '$watchDirectoryJobName', to enable you should mount a directory into 'C:\deploy'.")
}

# print ready message
Write-Host "$(Get-Date -Format $timeFormat): Development ENTRYPOINT, ready!"

& "C:\\service\\$($env:WORKER_EXECUTABLE_NAME_ENV)"