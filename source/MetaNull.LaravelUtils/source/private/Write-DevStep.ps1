<#
    .SYNOPSIS
    Writes a step message with appropriate icon and color

    .DESCRIPTION
    Displays a step message in the development process with rocket icon and magenta color

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevStep "Starting Laravel server..."
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "Rocket"
    Write-Host "$icon $Message" -ForegroundColor $ModuleColorStep
}
