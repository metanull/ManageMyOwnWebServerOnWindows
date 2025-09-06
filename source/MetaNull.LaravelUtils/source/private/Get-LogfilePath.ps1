<#
.SYNOPSIS
    Returns the path to the Laravel log file.

.PARAMETER Path
    The root directory of the Laravel application.

.OUTPUTS
    Returns the full path to the Laravel log file.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path
)
End {
    return Join-Path -Path $Path -ChildPath $script:ModuleLaravelLogFile
}