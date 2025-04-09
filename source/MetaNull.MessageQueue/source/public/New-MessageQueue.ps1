<#
.SYNOPSIS
    Create a new message queue.
.DESCRIPTION
    This function creates a new message queue.
.PARAMETER 
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([guid])]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Name,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateRange(1, 10000)]
    [int]$MaximumSize = 1000,
    
    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateRange(1, 365)]
    [int]$MessageRetentionPeriod = 7
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($MetaNull.MessageQueue.Lock)
    try {
        # Check if the queue already exists
        $Existing = Get-ChildItem "MetaNull:\MessageQueue" | Where-Object {
            ($_ | Get-ItemProperty | Select-Object -ExpandProperty Name | Where-Object { 
                $_ -eq $Name
            })
        }
        if ($Existing) {
            throw "MessageQueue with name $Name already exists."
        }

        # Add the messages
        $Id = New-Guid
        New-Item -Path "MetaNull:\MessageQueue\$Id" | Out-Null
        New-ItemProperty -Path "MetaNull:\MessageQueue\$Id" -Name 'Name' -Value $Name -Force | Out-Null
        New-ItemProperty -Path "MetaNull:\MessageQueue\$Id" -Name 'MaximumSize' -Value $MaximumSize -Force | Out-Null
        New-ItemProperty -Path "MetaNull:\MessageQueue\$Id" -Name 'MessageRetentionPeriod' -Value $MessageRetentionPeriod -Force | Out-Null
        New-ItemProperty -Path "MetaNull:\MessageQueue\$Id" -Name 'MessageCount' -Value 0 -Force | Out-Null
        New-ItemProperty -Path "MetaNull:\MessageQueue\$Id" -Name 'LastMessage' -Value '' -Force | Out-Null
        New-Item -Path "MetaNull:\MessageQueue\$Id\Messages" | Out-Null
        return $Id
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.MessageQueue.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}