<#
    .SYNOPSIS
    Writes a header message with appropriate icon and color

    .DESCRIPTION
    Displays a header message with celebration icon and white color for section headers

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevHeader "Starting Laravel Development Environment"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "Celebration"
    Write-Host ""
    Write-Host "$icon $Message" -ForegroundColor White
    Write-Host ""
}
