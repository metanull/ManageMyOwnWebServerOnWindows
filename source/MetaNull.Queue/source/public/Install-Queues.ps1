<#
    .SYNOPSIS
    Initialize the Windows Registry with the module's configuration
#>
[CmdletBinding()]
[OutputType()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [switch] $Force
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if((Test-QueuesInstalled -Scope $Scope) -eq $true -and -not ($Force.IsPresent -and $Force)) {
            # Already initialized
            Write-Verbose "Registry already initialized for $Scope"
            return
        }

        # Create the registry key
        $RootPath = Get-RegistryPath -Scope $Scope
        if(Test-Path -Path $RootPath -PathType Leaf) {
            throw "Registry key $RootPath is a leaf (container was expected)"
        }
        Write-Verbose "Creating registry key $RootPath"
        New-Item -Path $RootPath -Force:$Force | Out-Null
        $RootPath = Resolve-Path -Path $RootPath

        # Create a sub-key for the queues
        $ChildPath = Join-Path -Path $RootPath -ChildPath 'Queues'
        Write-Verbose "Creating registry key $ChildPath"
        New-Item -Path $ChildPath -Force:$Force | Out-Null
        
        # Create a sub-key for the initialization status
        $ChildPath = Join-Path -Path $RootPath -ChildPath 'Initialized'
        Write-Verbose "Creating registry key $ChildPath"
        $Initialized = New-Item -Path $ChildPath -Force:$Force

        $Initialized | New-ItemProperty -Name 'Initialized' -Value 1 -PropertyType 'DWord' -Force:$Force | Out-Null
        $Initialized | New-ItemProperty -Name 'Date' -Value (Get-Date|ConvertTo-Json) -PropertyType 'String' -Force:$Force | Out-Null
        $Initialized | New-ItemProperty -Name 'Version' -Value $Constants.Version -PropertyType 'String' -Force:$Force | Out-Null
        $Initialized | New-ItemProperty -Name 'Author' -Value $env:USERNAME -PropertyType 'String' -Force:$Force | Out-Null
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }    
}