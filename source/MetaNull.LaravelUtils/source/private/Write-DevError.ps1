<#
    .SYNOPSIS
    Writes an error message with appropriate icon and color

    .DESCRIPTION
    Displays an error message with error icon and red color

    .PARAMETER Message
    The message to display

    .EXAMPLE
    Write-DevError "Failed to start server"
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

End {
    $icon = Get-ModuleIcon "Error"
    Write-Host "$icon $Message" -ForegroundColor $ModuleColorError
}
