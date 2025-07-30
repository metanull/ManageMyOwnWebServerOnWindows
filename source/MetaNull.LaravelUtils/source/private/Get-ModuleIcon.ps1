<#
    .SYNOPSIS
    Gets an icon for display based on PowerShell version capabilities

    .DESCRIPTION
    Returns either an emoji icon (PowerShell 7+) or plain text fallback (PowerShell 5.1)

    .PARAMETER IconName
    The name of the icon to retrieve

    .EXAMPLE
    Get-ModuleIcon "Rocket"
    Returns "`u{1F680}" on PowerShell 7+ or "[START]" on PowerShell 5.1
#>
[CmdletBinding()]
[OutputType([string])]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$IconName,

    [Parameter()]
    [ValidateSet("plaintext", "unicode", "auto")]
    [string]$Mode = "auto"
)

End {
    if ($Mode -eq "plaintext" ) {
        $PlainText = $true
    }
    elseif ($Mode -eq "unicode") {
        $PlainText = $false
    }
    else {
        $PlainText = $script:UseEmojis -eq $false
    }

    if ($PlainText) {
        $IconSet = $script:ModuleIcons.PlainText
    }
    else {
        $IconSet = $script:ModuleIcons.Unicode
    }
    
    if ($IconSet.ContainsKey($IconName)) {
        return $IconSet[$IconName]
    }
    else {
        Write-Warning "Icon '$IconName' not found."
    }
    return "?"
}
