<#
    .SYNOPSIS
    Writes a success message with appropriate icon and color

    .DESCRIPTION
    Displays a success message with checkmark icon and green color

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevSuccess "Server started successfully!"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "CheckMark"
    Write-Host "$icon $Message" -ForegroundColor $ModuleColorSuccess
}
