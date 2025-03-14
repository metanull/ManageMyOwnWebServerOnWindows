<#
    .SYNOPSIS
    Get all the properties of a RegistryKey as a hashtable
#>
[CmdletBinding()]
[OutputType([hashtable])]
param(
    [Parameter(Mandatory)]
    [Microsoft.Win32.RegistryKey]
    $RegistryKey
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        [hashtable]$Properties = @{}
        $RegistryKey | Select-Object -ExpandProperty Property | ForEach-Object {
            $Properties += @{$_ = $RegistryKey.GetValue($_)}
        }
        $Properties | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}