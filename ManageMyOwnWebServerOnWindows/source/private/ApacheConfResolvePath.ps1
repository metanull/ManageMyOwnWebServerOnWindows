<#
.SYNOPSIS
    Resolves a path in an Apache configuration file.
.DESCRIPTION
    Resolves a path in an Apache configuration file.
.PARAMETER Path
    The path to resolve.
.PARAMETER ServerRoot
    The Apache server root.
.EXAMPLE
    ApacheConfResolvePath -Path "conf/httpd.conf" -ServerRoot "C:/Apache24"
    Returns "C:/Apache24/conf/httpd.conf".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    [AllowNull()]
    $Path,
    [Parameter(Mandatory=$true,Position=1)]
    $ServerRoot
)
Process {
    if(-not $Path) {
        return $null
    }
    if(-not ([System.IO.Path]::IsPathRooted($Path))) {
        Join-Path $ServerRoot $Path | Write-Output
    } else {
        $Path | Write-Output
    }
}