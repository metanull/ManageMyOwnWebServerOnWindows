<#
    .SYNOPSIS
        Get the Command(s) in a Queue, sorted by their number
#>
[CmdletBinding(DefaultParameterSetName = 'Name')]
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
    [string] $QueueId,

    [Parameter(Mandatory, ParameterSetName = 'Name')]
    [string] $QueueName
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        $Constants = Get-ModuleConstant
        Write-Debug "Obtaining Mutex for $($Constants.Mutex.QueueReadWrite.MutexName)"
        $Mutex = [System.Threading.Mutex]::new($false, $Constants.Mutex.QueueReadWrite.MutexName)
        if (-not ($Mutex.WaitOne(([int]$Constants.Mutex.QueueReadWrite.MutexNameTimeout)))) {
            throw "Failed to obtain the Mutex within the timeout period."
        }

        if($pscmdlet.ParameterSetName -eq 'GUID') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues" 
            $Items = Get-ChildItem -Path $Path | Where-Object { 
                ($_ | Get-ItemProperty -Name 'Id' -ErrorAction SilentlyContinue) -and ($_ | Get-ItemPropertyValue -Name 'Id') -eq $QueueId 
            }
        } elseif($pscmdlet.ParameterSetName -eq 'Name') {
            $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$QueueName"
            $Items = ,(Get-Item -Path $Path)
        }
        $Items | ForEach-Object {
            Write-Verbose "Getting Commands from $Path"
            $Path = Join-Path -Path $_.PSPath $ChildPath 'Commands' -Resolve
            # Get the commands sorted on their number
            Get-ChildItem -Path $Path | Sort-Object -Descending {
               [int](($_.Name | Split-Path -Leaf) -replace '\D')
            } | ForEach-Object {
                $Properties = Get-RegistryKeyProperties -RegistryKey $_
                # Return the command
                [PSCustomObject]@{
                    QueueName = $QueueName
                    QueueId = $QueueId
                    Name = $_ | Split-Path -Leaf
                    Number = [int](($_.Name | Split-Path -Leaf) -replace '\D')
                    Command = $Properties['Command']
                    Properties = $Properties
                } | Write-Output
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