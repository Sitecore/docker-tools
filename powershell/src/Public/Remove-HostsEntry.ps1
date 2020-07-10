Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Removes a host entry from the system hosts file.
.DESCRIPTION
    Removes a host entry with the specified Hostname from the system hosts file (if it exist).
    A backup of the current hosts file is taken before updating.
.PARAMETER Hostname
    The hostname to remove.
.INPUTS
    None. You cannot pipe objects to Remove-HostsEntry.
.OUTPUTS
    None. Remove-HostsEntry does not generate any output.
.EXAMPLE
    PS C:\> Remove-HostsEntry 'my.host.name'
#>
function Remove-HostsEntry
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Hostname,

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
    $pattern = '^[0-9a-f.:]+\s+' + [Regex]::Escape($HostName) + '\s*$'

    $hostsContent = @(Get-Content -Path $Path -Encoding UTF8)

    if (-not $hostsContent) {
        Write-Verbose "The hosts file is empty, hosts have not been updated"
        return
    }

    # Check if exists
    $updatedHostsContent = $hostsContent | Select-String -Pattern $pattern -NotMatch
    if ($null -ne $updatedHostsContent -and @(Compare-Object -ReferenceObject $hostsContent -DifferenceObject $updatedHostsContent).Count -eq 0) {
        Write-Verbose "No existing host entry found for hostname '$HostName'"
        return
    }

    # Remove it
    WriteLines -File $Path -Content $updatedHostsContent -Encoding ([System.Text.Encoding]::UTF8)
    Write-Verbose -Message "Host entry for hostname '$HostName' has been removed"
}