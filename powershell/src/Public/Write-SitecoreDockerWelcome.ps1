Set-StrictMode -Version Latest

<#
.SYNOPSIS
    Welcomes you to Docker-based Sitecore development.
.DESCRIPTION
    :)
.EXAMPLE
    PS C:\> Write-SitecoreDockerWelcome
.INPUTS
    None.
.OUTPUTS
    None.
#>
function Write-SitecoreDockerWelcome {

    $lighthouse = @"
     \               +               /                                   /``\
       \             |             /
         \           |           /            /``\
           \        / \        /
             \    /______\   /
             /   |___|___|   \
           /   |;|       |;|   \
         /      \\.     . /      \ 
       /         ||:   . |         \                         /``\
     /           ||:     |           \
                 ||:     | 
                 ||:    .|
                 ||      |
                 |:      |
                 ||:__ . |                ------------------
___________ _ ||_| |_.|  |________________|                |___________________
......................................... |                | ..................
.............................. -------------------------------------- .........
........ _________  .......... |                   |                | .........
        /          |           |                   |                |
       /          /    ------------------------------------------------------
       |         |     |                  |                 |               |
       |         |     |                  |                 |               |
------          ---------------------------------------------------------------
\         _____ _______ ________ ______  ______ _____ ________   _____        /
 \       / ____|__   __|__   __|   ___/ / ____/  ___  |   __  \ |  ___|      / 
~~\     | (___    | |     | |   | |__  | |    | |   | |  |__)  || |__       /~~
~~~\     \____\   | |     | |   |  __| | |    | |   | |  _    / |  __|     /~~~
~~~~\    ____| )__| |__   | |   |  |___| |___ | |___| |  | \  \ | |___    /~~~~
~~~~~\  |_____/|________| |_|   |____ / \_____/\____/ |__|  \_  \_____|  /~~~~~
~~~~~~\                                                                 /~~~~~~
~~~~~~~\                                                               /====~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"@
    $index = 1
    ($lighthouse -split "\r?\n|\r") | ForEach-Object {
        $line = $_

        # lighthouse rays
        if ($index -lt 11) {
            $col = 1
            [char[]]$line | ForEach-Object {
                # find light rays by column
                if (($col -gt 5 -and $col -lt 15) -or ($col -gt 29 -and $col -lt 39)) {
                    Write-Host $_ -ForegroundColor Yellow -NoNewline
                }
                else {
                    Write-Host $_ -NoNewline
                }
                $col++
            }
            Write-Host
        }

        # grass
        elseif ($index -gt 16 -and $index -lt 20) {
            [char[]]$line | ForEach-Object {
                # find grass by character
                if ($_ -eq '.') {
                    Write-Host $_ -ForegroundColor Green -NoNewline
                }
                else {
                    Write-Host $_ -NoNewline
                }
            }
            Write-Host
        }

        # ship / water / logo
        elseif ($index -gt 24) {
            $col = 1
            [char[]]$line | ForEach-Object {
                # find letters by column and line
                if ($col -gt 8 -and $col -lt 72 -and $index -lt 33) {
                    Write-Host $_ -ForegroundColor Red -NoNewline
                }
                # find water by character
                elseif ($_ -eq "~" -or $_ -eq "=") {
                    Write-Host $_ -ForegroundColor Blue -NoNewline
                }
                else {
                    Write-Host $_ -NoNewline
                }
                $col++
            }
            Write-Host
        }

        else {
            Write-Host $_
        }
        $index++
    }
}