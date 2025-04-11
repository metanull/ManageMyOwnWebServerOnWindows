<#
.SYNOPSIS
    Clears the message queue from outdated or excess messages.
.DESCRIPTION
    This function clears the message queue from outdated or excess messages.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Medium')]
[OutputType([void])]
param()
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $MetaNull.MessageQueue.MutexMessageQueue.WaitOne() | Out-Null

        $CurrentDate = (Get-Date)
        $Queues = Get-Item "MetaNull:\MessageQueue" | Get-ChildItem
        $Queues | Foreach-Object {
            Write-Verbose "Processing MessageQueue $($_.PSChildName)"
            $Properties = $_ | Get-ItemProperty

            # Remove Excess Messages
            if($Properties.MaximumSize -gt 0) {
                $Children = $_ | Get-ChildItem | Sort-Object { $_ | Get-ItemProperty | Select-Object -ExpandProperty Index }
                if($Children.Count -gt $Properties.MaximumSize) {
                    $ExcessMessages = $Children.Count - $Properties.MaximumSize
                    Write-Verbose "Removing $ExcessMessages excess message(s) from MessageQueue"
                    $Children | Select-Object -First $ExcessMessages | Remove-Item
                }
            }
            # Remove Outdated Messages
            if($Properties.MessageRetentionPeriod -gt 0) {
                $DateConstraint = $CurrentDate.AddDays(-$Properties.MessageRetentionPeriod)
                $Children = $_ | Get-ChildItem | Where-Object {
                    $DateConstraint -gt ([datetime]($_ | Get-ItemProperty | Select-Object -ExpandProperty Date | ConvertFrom-Json | Select-Object -ExpandProperty Value))
                }
                if($Children.Count -gt 0) {
                    $ExcessMessages = $Children.Count
                    Write-Verbose "Removing $ExcessMessages outdated message(s) from MessageQueue"
                    $Children | Remove-Item
                }
            }
        }
        
        # Remove leftover messages from the MessageStore
        $MessageIdList = Get-Item "MetaNull:\MessageQueue" | Get-ChildItem | Get-ChildItem | Get-ItemProperty | Select-Object -ExpandProperty MessageId | Select-Object -unique
        $Children = Get-Item "MetaNull:\MessageStore" | Get-ChildItem | Where-Object {
            $_.PSChildName -notin $MessageIdList
        }
        if($Children.Count -gt 0) {
            $ExcessMessages = $Children.Count
            Write-Verbose "Removing $ExcessMessages unlinked message(s) from MessageStore"
            $Children | Remove-Item
        }
    } finally {
        $MetaNull.MessageQueue.MutexMessageQueue.ReleaseMutex()
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}