<#
    .SYNOPSIS
    Writes a warning message with appropriate icon and color

    .DESCRIPTION
    Displays a warning message with warning icon and yellow color

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevWarning "Port is already in use"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "Warning"
    Write-Host "$icon $Message" -ForegroundColor $ModuleColorWarning
}
