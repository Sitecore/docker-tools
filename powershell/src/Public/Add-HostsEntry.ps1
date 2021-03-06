Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Adds a host entry to the system hosts file.
.DESCRIPTION
    Adds a host entry with the specified Hostname and IPAddress to the system hosts file (if it does not already exist).
    A backup of the current hosts file is taken before updating.
.PARAMETER Hostname
    The hostname to use for the entry.
.PARAMETER IPAddress
    The IP address to use for the entry. Default is 127.0.0.1.
.INPUTS
    None. You cannot pipe objects to Add-HostsEntry.
.OUTPUTS
    None. Add-HostsEntry does not generate any output.
.EXAMPLE
    PS C:\> Add-HostsEntry 'my.host.name'
#>
function Add-HostsEntry
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Hostname,

        [string]
        [ValidateNotNullOrEmpty()]
        $IPAddress = "127.0.0.1",

        [string]
        $Path = (Join-Path -Path $env:windir -ChildPath "system32\drivers\etc\hosts")
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "No hosts file found, hosts have not been updated"
        return
    }

    # Create backup
    Copy-Item $Path "$Path.backup"
    Write-Verbose "Created backup of hosts file to $Path.backup"

    # Build regex match pattern
    $pattern = '^' + [Regex]::Escape($IPAddress) + '\s+' + [Regex]::Escape($HostName) + '\s*$'

    $hostsContent = @(Get-Content -Path $Path -Encoding UTF8)

    # Check if exists
    $existingEntries = $hostsContent -match $pattern
    if ($existingEntries.Count -gt 0) {
        Write-Verbose "Existing host entry found for $IPAddress with hostname '$HostName'"
        return
    }

    # Add it
    $hostsContent += "$IPAddress`t$HostName"
    WriteLines -File $Path -Content $hostsContent -Encoding ([System.Text.Encoding]::UTF8)
    Write-Verbose "Host entry for $IPAddress with hostname '$HostName' has been added"
}