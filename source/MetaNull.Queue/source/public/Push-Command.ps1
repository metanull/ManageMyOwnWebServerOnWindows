<#
    .SYNOPSIS
        Add a new Command at the end of a queue
#>
[CmdletBinding(DefaultParameterSetName = 'Name')]
[OutputType([int])]
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
    [string] $Name,

    [Parameter(Mandatory)]
    [string] $Command
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        $Constants = Get-ModuleConstant
        $Constants | Write-Debug
        Write-Debug "Obtaining Mutex for $($Constants.Synch.Queue.MutexName)"
        $Mutex = [System.Threading.Mutex]::new($false, $Constants.Synch.Queue.MutexName)
        if (-not ($Mutex.WaitOne(([int]$Constants.Synch.Queue.MutexNameTimeout)))) {
            throw "Failed to obtain the Mutex within the timeout period."
        }

        if($pscmdlet.ParameterSetName -eq 'GUID') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues" 
            $Items = Get-ChildItem -Path $Path | Where-Object { 
                ($_ | Get-ItemProperty -Name 'Id' -ErrorAction SilentlyContinue) -and ($_ | Get-ItemPropertyValue -Name 'Id') -eq $Id 
            }
        } elseif($pscmdlet.ParameterSetName -eq 'Name') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name"
            $Items = ,(Get-Item -Path $Path)
        }
        $Items | ForEach-Object {
            $Path = Join-Path -Path $_.PSPath $ChildPath 'Commands' -Resolve
            Write-Verbose "Adding Command to $Path"
            # Find the next command number
            $Number = 1
            Get-ChildItem -Path $Path | Sort-Object -Descending {
               [int](($_.Name | Split-Path -Leaf) -replace '\D')
             } | Select-Object -First 1 | ForEach-Object {
               $Number = ([int](($_.Name | Split-Path -Leaf) -replace '\D')) + 1
            }
            # Add the new command
            Write-Verbose "Command number is $Number"
            $Item = New-Item -Path $Path -Name "$Number"
            $Item | New-ItemProperty -Name Command -Value $Command -PropertyType String | Out-Null
            $Item | New-ItemProperty -Name CreatedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
            # Return the command number
            $Number | Write-Output
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