<#
    .SYNOPSIS
        Returns the list of Queues

    .DESCRIPTION
        This function returns the list of Queues, based on the Scope and Name parameters.
        The Scope parameter can be set to 'AllUsers' or 'CurrentUser'.
        The Name parameter can be used to filter the results by the Queue name. It supports wildcards. The default is '*'.

    .PARAMETER Scope
        The Scope parameter can be set to 'AllUsers' or 'CurrentUser'.
        The default is 'AllUsers'.

    .PARAMETER Name
        The Name parameter can be used to filter the results by the Queue name. It supports wildcards. The default is '*'.

    .OUTPUTS
        The function returns a PSCustomObject with the following properties:
        - Id: The Queue Id
        - Name: The Queue Name
        - Properties: The Queue properties
        - RegistryKey: The Registry Key

    .EXAMPLE
        Find-Queue -Scope 'AllUsers'
        Returns all Queues (for all users).
    .EXAMPLE
        Find-Queue Meta*
        Returns all Queues (for all users) that start with 'Meta'.
    .EXAMPLE
        Find-Queue -Scope 'CurrentUser' -Name 'Meta*'
        Returns all Queues (for the current user) that start with 'Meta'.
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers',

    [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
    [string] $Name = '*'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($METANULL_QUEUE_CONSTANTS.Lock)
    try {
        $Path = Get-RegistryPath -Scope $Scope -ChildPath "Queues\$Name"
        "Finding in $Path" | Write-Debug
        Get-Item -Path $Path | ForEach-Object {
            $Properties = Get-RegistryKeyProperties -RegistryKey $_
            $Queue = [PSCustomObject]@{
                QueueId = $Properties['Id']
                Name = $_ | Split-Path -Leaf
                Properties = $Properties
                Commands = @()
                FirstCommandIndex = $null
                LastCommandIndex = $null
                RegistryKey = $_
            }

            $CommandPath = Join-Path -Path $_.PSPath -ChildPath 'Commands'

            $Queue.Commands = Get-ChildItem -Path $CommandPath | Sort-Object -Descending {
                    [int](($_.Name | Split-Path -Leaf) -replace '\D')
                } | ForEach-Object {
                    $CommandIndex = ([int](($_.Name | Split-Path -Leaf) -replace '\D'))
                    if ($Queue.FirstCommandIndex -eq $null -or $CommandIndex -lt $Queue.FirstCommandIndex) {
                        $Queue.FirstCommandIndex = $CommandIndex
                    }
                    if ($Queue.LastCommandIndex -eq $null -or $CommandIndex -gt $Queue.LastCommandIndex) {
                        $Queue.LastCommandIndex = $CommandIndex
                    }
                    [pscustomobject]@{
                        Index = $CommandIndex
                        Name = $_ | Get-ItemPropertyValue -Name 'Name'
                        Command = $_ | Get-ItemPropertyValue -Name 'Command'
                        CreatedDate = $_ | Get-ItemPropertyValue -Name 'CreatedDate'
                        RegistryKey = $_
                    }
                }

            $Queue | Write-Output
        }
    } finally {
        [System.Threading.Monitor]::Exit($METANULL_QUEUE_CONSTANTS.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
