<#
    .SYNOPSIS
        Tests if the registry was initialized
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Path = Get-RegistryPath -Scope $Scope -ChildPath 'Install'
        Write-verbose "Checking registry key $Path"
        $Initialized = Get-Item -Path $Path
        Write-Verbose "Checking registry key's 'Initialized' property"
        $InitializedValue = $Initialized | Get-ItemPropertyValue -Name 'Done'
        return $InitializedValue -eq 1
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}