<#
    .SYNOPSIS
    Writes an info message with appropriate icon and color

    .DESCRIPTION
    Displays an informational message with info icon and cyan color

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevInfo "Found PHP version: 8.2.12"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "Info"
    Write-Host "$icon $Message" -ForegroundColor $ModuleColorInfo
}
