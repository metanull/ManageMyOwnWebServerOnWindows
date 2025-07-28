<#
    .SYNOPSIS
    Gets an icon for display based on PowerShell version capabilities

    .DESCRIPTION
    Returns either an emoji icon (PowerShell 7+) or plain text fallback (PowerShell 5.1).
    This is a public wrapper around the private Get-ModuleIcon function.

    .PARAMETER IconName
    The name of the icon to retrieve. Valid values include:
    Rocket, CheckMark, Warning, Info, Error, Celebration, MobilePhone,
    Satellite, Lightning, Wrench, Books, GreenHeart, Key, FloppyDisk

    .OUTPUTS
    String - The icon character or text representation

    .EXAMPLE
    Get-DevIcon "Rocket"
    Returns "🚀" on PowerShell 7+ or "[START]" on PowerShell 5.1

    .EXAMPLE
    $icon = Get-DevIcon "CheckMark"
    Write-Host "$icon Operation completed successfully!"
#>
[CmdletBinding()]
[OutputType([string])]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("Rocket", "CheckMark", "Warning", "Info", "Error", "Celebration",
                 "MobilePhone", "Satellite", "Lightning", "Wrench", "Books",
                 "GreenHeart", "Key", "FloppyDisk")]
    [string]$IconName
)

End {
    return Get-ModuleIcon -IconName $IconName
}
