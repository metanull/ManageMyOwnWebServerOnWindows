<#
    .SYNOPSIS
        Tests if the registry was initialized
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Initialized = Get-Item -Path (Get-RegistryPath -Scope $Scope -ChildPath 'Initialized')
        $InitializedValue = $Initialized | Get-ItemPropertyValue -Name 'Initialized'
        return $InitializedValue -eq 1
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}