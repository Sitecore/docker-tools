Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Sets a variable in a Docker environment (.env) file.
.DESCRIPTION
    Sets a variable in a Docker environment (.env) file.
    Assumes .env file is in the current directory by default.
.PARAMETER Variable
    Specifies the variable name.
.PARAMETER Value
    Specifies the variable value.
.PARAMETER AsLiteral
    Specifies whether the Value should be written as a literal (i.e wrapped in single quotes)
.PARAMETER Path
    Specifies the Docker environment (.env) file path. Assumes .env file is in the current directory by default.
.EXAMPLE
    PS C:\> Set-EnvFileVariable -Variable VAR1 -Value "value one"
.EXAMPLE
    PS C:\> "value one" | Set-EnvFileVariable "VAR1"
.EXAMPLE
    PS C:\> Set-EnvFileVariable -Variable VAR1 -Value "value one" -Path .\src\.env
.EXAMPLE
    PS C:\> Set-EnvFileVariable -Variable VAR1 -Value "literal $tring" -AsLiteral
.INPUTS
    System.String. You can pipe in the Value parameter.
.OUTPUTS
    None.
#>
function Set-EnvFileVariable
{
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Variable,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [AllowEmptyString()]
        [string]
        $Value,

        [switch]
        $AsLiteral = $false,

        [string]
        $Path = ".\.env"
    )

    if (!(Test-Path $Path)) {
        throw "The environment file $Path does not exist"
    }
    
    if ($AsLiteral){
          # Escape any ' to avoid terminating the value unexpectedly
        $Value = "'$($Value.Replace("'", "''"))'"
    }
    
    $found = $false

    $lines = @(Get-Content $Path -Encoding UTF8 | ForEach-Object {
        if ($_ -imatch "^$Variable=.*") {
            # Escape any '$' to prevent being used as a regex substitution
            $Value = $Value.Replace('$', '$$')
            $_ -ireplace "^$Variable=.*", "$Variable=$Value"
            $found = $true
        }
        else {
            $_
        }
    })

    if (!$found) {
        $lines += "$Variable=$Value"
    }

    WriteLines -File (Resolve-Path $Path) -Content $lines -Encoding ([System.Text.Encoding]::UTF8)
}
