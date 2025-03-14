<#
    .SYNOPSIS
    Get the path to the module's registry key
#>
[CmdletBinding()]
[OutputType([string])]
param(
    [Parameter(Mandatory)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope,

    [Parameter(Mandatory=$false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $ChildPath = $null,

    [switch] $Resolve
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Constants = Get-ModuleConstant
        if($Scope -eq 'CurrentUser') {
            $Path = Join-Path -Path 'HKCU:' -ChildPath $Constants.Registry.Path
        } else {
            $Path = Join-Path -Path 'HKLM:' -ChildPath $Constants.Registry.Path
        }
        if($ChildPath) {
            $Path = Join-Path -Path $Path -ChildPath $ChildPath
        }
        if($Resolve) {
            $Path = Resolve-Path -Path $Path
        }
        $Path | Write-Output
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}