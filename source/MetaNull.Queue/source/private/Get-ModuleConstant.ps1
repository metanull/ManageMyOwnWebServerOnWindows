<#
    .SYNOPSIS
        Return the Module Constants variable
#>
[CmdletBinding()]
[OutputType([hashtable])]
param()
End {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        Get-Variable -Name METANULL_QUEUE_CONSTANTS -ValueOnly -Scope script | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}