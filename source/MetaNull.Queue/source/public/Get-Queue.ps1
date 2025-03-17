<#
    .SYNOPSIS
        Returns the list of Queues

    .DESCRIPTION
        Returns the list of Queues

    .PARAMETER Id
        The Id of the Queue to return

    .PARAMETER Name
        The filter to apply on the name of the Queues
        Filter supports wildcards

    .EXAMPLE
        # Get all the Queues
        Get-Queue

    .EXAMPLE
        # Get the Queue with the Id '00000000-0000-0000-0000-000000000000'
        Get-Queue -Id '00000000-0000-0000-0000-000000000000'

    .EXAMPLE
        # Get the Queues with the name starting with 'Queue'
        Get-Queue -Name 'Queue*'

#>
[CmdletBinding()]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [guid] $Id = [guid]::Empty,

    [Parameter(Mandatory = $false, Position = 1)]
    [string] $Name = '*'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    try {
        # Set the filter to '*' or the 'Id'
        $Filter = '*'
        if($Id -ne [guid]::Empty) {
            $Filter = $Id.ToString()
        }

        [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
        try {
            # Get the queue(s)
            Get-Item -Path "MetaNull:\Queues\$Filter" | Foreach-Object {
                $Queue = $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* 
                $Queue | Add-Member -MemberType NoteProperty -Name 'RegistryKey' -Value $RegistryKey
                $Queue | Add-Member -MemberType NoteProperty -Name 'Commands' -Value @()
                # Return the queue object
                $Queue | Write-Output
            } | Where-Object {
                # Filter the queue(s) by 'Name'
                $_.Name -like $Name
            } | ForEach-Object {
                # Add command(s) to the queue object
                $_.Commands = Get-ChildItem "MetaNull:\Queues\$($_.Id)\Commands" | Foreach-Object {
                    $Command = $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS*
                    $Command | Add-Member -MemberType NoteProperty -Name 'RegistryKey' -Value $RegistryKey
                    $Command | Write-Output
                }
                # Return the Queue object
                $_ | write-output
            }
        } finally {
            [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}
