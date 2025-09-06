<#
.SYNOPSIS
    Watches the Laravel logs for changes and outputs new log entries in real-time.
.DESCRIPTION
    This script monitors the Laravel log file for any new entries and outputs them to the console in
    real-time. It is useful for debugging and monitoring Laravel activity during development.
.PARAMETER Path
    The path to the Laravel application root directory.
.PARAMETER Clear
    If specified, clears the log file before starting to watch it.
.EXAMPLE
    Watch-Logfile -Path "C:\path\to\laravel"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({ Test-LaravelPath -Path $_ -PathType Container })]
    [string]$Path,

    [switch]$Clear
)
End {
    $LogFile = Get-LogfilePath -Path $Path
    if(-not (Test-Path -Path $LogFile -PathType Leaf)) {
        Write-Warning "Log file does not exist at $LogFile"
        return
    }
    if($Clear) {
        Clear-Content -Path $LogFile -ErrorAction Stop
    }
    Get-Content -Path $LogFile -Wait -ErrorAction Stop
}