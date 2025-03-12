<#
.SYNOPSIS
    Replace constant in Apache configuration file.
.DESCRIPTION
    Replace constant in Apache configuration file.
.PARAMETER Value
    The value to replace the constants in.
.PARAMETER Constants
    The constants to replace in the value.
.EXAMPLE
    ApacheConfReplaceConstant -Value "${SRVROOT}/conf/httpd.conf" -Constants @{ SRVROOT = "C:/Apache24" }
    Returns "C:/Apache24/conf/httpd.conf".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    $Value,
    [Parameter(Mandatory = $true, Position = 1)]
    $Constants
)
Process {
    while ($Value -match '\$\{(.*?)\}') {
        if (-not $Constants.ContainsKey($Matches[1])) {
            break
        }
        $Value = $Value.Replace($Matches[0], $Constants[$Matches[1]])
    }
    $Value | Write-Output
}