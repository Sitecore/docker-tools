param(
    [Parameter(HelpMessage="The block of tests to run in the scope of the module")]
    [ScriptBlock]$TestScope = $null
)

Function Test-ParamIsMandatory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandName,
        [Parameter(Mandatory=$true)]
        [string]$Parameter,
        [string]$SetName = ''
    )

    $cmd = Get-Command $CommandName
    $attr = $cmd.Parameters.$Parameter.Attributes | Where-Object { $_.TypeId -eq [System.Management.Automation.ParameterAttribute] }
    if($SetName) {
        $attr = $attr | Where-Object { $_.ParameterSetName -eq $SetName }
    }
    $attr.Mandatory
}

Function Test-ParamValidateSet {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandName,
        [Parameter(Mandatory=$true)]
        [string]$Parameter,
        [string[]]$Values
    )

    $cmd = Get-Command $CommandName
    $attr = $cmd.Parameters.$Parameter.Attributes | Where-Object { $_.TypeId -eq [System.Management.Automation.ValidateSetAttribute] }

    Compare-Sets $attr.ValidValues $Values
}

Function Compare-Sets {
    param(
        [Parameter(Mandatory=$true)]
        [psobject[]]$Left,
        [Parameter(Mandatory=$true)]
        [psobject[]]$Right
    )

    $results = Compare-Object $Left $Right
    if($results){
        $formatter = {
            $obj = New-Object psobject -Property @{
                State = if($_.SideIndicator.Contains('>')) { 'Missing' } else { 'Extra' }
                Value = $_.InputObject
            }

            Write-Host "$($Obj.State) => $($obj.Value)"
        }

        $results | ForEach-Object $formatter
        return $false
    }

    $true
}