<#
    .SYNOPSIS
    Tests if a command is available in the current session

    .DESCRIPTION
    Checks if a command exists and can be executed in the current PowerShell session

    .PARAMETER Command
    The command name to test

    .OUTPUTS
    Boolean - True if command exists, False otherwise

    .EXAMPLE
    Test-DevCommand "php"
    Returns $true if PHP is available in PATH
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $true)]
    [string]$Command
)

End {
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}
