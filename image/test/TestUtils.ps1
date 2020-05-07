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