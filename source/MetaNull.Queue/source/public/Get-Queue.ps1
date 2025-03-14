<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'CurrentUser',

    [Parameter(Mandatory, ParameterSetName = 'GUID')]
    [ValidateScript({ 
        $ref = [guid]::Empty
        return [guid]::TryParse($_, [ref]$ref)
    })]
    [string] $Id,

    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string] $Name
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if($pscmdlet.ParameterSetName -eq 'Default') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues"
            $Items = Get-ChildItem -Path $Path
        } elseif($pscmdlet.ParameterSetName -eq 'GUID') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues" 
            $Items = Get-ChildItem -Path $Path | Where-Object { 
                ($_ | Get-ItemProperty -Name 'Id' -ErrorAction SilentlyContinue) -and ($_ | Get-ItemPropertyValue -Name 'Id') -eq $Id 
            }
        } elseif($pscmdlet.ParameterSetName -eq 'Name') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name"
            $Items = ,(Get-Item -Path $Path)
        }
        $Items | ForEach-Object {
            $Properties = Get-RegistryKeyProperties -RegistryKey $_
            [PSCustomObject]@{
                Name = $_ | Split-Path -Leaf
                Id = $Properties['Id']
                Properties = $Properties
            }
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
