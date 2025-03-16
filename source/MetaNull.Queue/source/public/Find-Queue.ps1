<#
    .SYNOPSIS
        Returns the list of Queues

    .DESCRIPTION
        This function returns the list of Queues.
        The Name parameter can be used to filter the results by the Queue name. It supports wildcards. The default is '*'.

    .PARAMETER Name
        The Name parameter can be used to filter the results by the Queue name. It supports wildcards. The default is '*'.

    .OUTPUTS
        The function returns a PSCustomObject with the following properties:
        - Id: The Queue Id
        - Name: The Queue Name
        - Properties: The Queue properties
        - RegistryKey: The Registry Key

    .EXAMPLE
        Find-Queue
        Returns all Queues (for all users).
    .EXAMPLE
        Find-Queue Meta*
        Returns all Queues (for all users) that start with 'Meta'.
#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
    [string] $Name = '*'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
    try {
        "MetaNull:\Queues\*" | Write-Debug
        Get-Item -Path "MetaNull:\Queues\*" | ConvertFrom-QueueRegistry | Where-Object {
            $_.Name -like $Name
        } | Foreach-Object {
            $_.Commands = Get-ChildItem "MetaNull:\Queues\$($_.Id)\Commands" | ConvertFrom-CommandRegistry
            $_ | write-output
        }
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
