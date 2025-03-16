<#
    .SYNOPSIS
        Transform a RegistryKey of a Queue into an Object
#>
[CmdletBinding()]
[OutputType([hashtable])]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [Microsoft.Win32.RegistryKey]
    $RegistryKey
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Queue = $RegistryKey | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* 
        $Queue | Add-Member -MemberType NoteProperty -Name 'Commands' -Value @()
        $Queue | Add-Member -MemberType NoteProperty -Name 'RegistryKey' -Value $RegistryKey
        $Queue | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}