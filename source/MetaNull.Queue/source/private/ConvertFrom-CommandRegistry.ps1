<#
    .SYNOPSIS
        Transform a RegistryKey of a Queues/Command into an Object
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
        $Queue = [PSCustomObject]@{
            Name = $RegistryKey | Split-Path | Split-Path | Get-ItemPropertyValue -Name 'Name'
            Id = $RegistryKey | Split-Path | Split-Path | Split-Path -Leaf
        }

        $Command = $RegistryKey | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* 
        $Command | Add-Member -MemberType NoteProperty -Name 'Queue' -Value $Queue
        $Command | Add-Member -MemberType NoteProperty -Name 'RegistryKey' -Value $RegistryKey
        $Command | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}