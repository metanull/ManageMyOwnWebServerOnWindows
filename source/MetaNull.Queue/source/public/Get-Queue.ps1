<#
    .SYNOPSIS
        Returns the list of Queues
#>
[CmdletBinding(DefaultParameterSetName = 'Default')]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

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
        $Constants = Get-ModuleConstant
        Write-Debug "Obtaining Mutex for $($Constants.Synch.Queue.MutexName)"
        $Mutex = [System.Threading.Mutex]::new($false, $Constants.Synch.Queue.MutexName)
        if (-not ($Mutex.WaitOne(([int]$Constants.Synch.Queue.MutexNameTimeout)))) {
            throw "Failed to obtain the Mutex within the timeout period."
        }

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
        if($Mutex) {
            Write-Debug "Releasing Mutex"
            $Mutex.ReleaseMutex()
            $Mutex.Dispose()
        }
    }
}
