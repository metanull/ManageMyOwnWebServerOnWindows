<#
.SYNOPSIS
    Clears the Laravel log file.

.PARAMETER Path
    The path to the Laravel application root directory.

.EXAMPLE
    Clear-Logfile -Path "C:\path\to\laravel"

    Clears the Laravel log file in the specified directory.
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-LaravelPath -Path $_ })]
    [string]$Path
)
End {
    $LogFile = Get-LogfilePath -Path $Path
    if ((Test-Path $LogFile -PathType Leaf) ) {
        Clear-Content -Path $LogFile -ErrorAction Stop
    } else {
        Write-Warning -Message "Log file does not exist at $LogFile"
    }
}