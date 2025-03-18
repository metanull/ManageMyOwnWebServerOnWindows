<#
    .SYNOPSIS
        Remove a Command from the top or bottom of the queue

    .DESCRIPTION
        Remove a Command from the top or bottom of the queue

    .PARAMETER Id
        The Id of the queue

    .PARAMETER Unshift
        If set, removes the command from the top of the queue

    .OUTPUTS
        [pscustomobject]

    .EXAMPLE
        $Command = Pop-QueueCommand -Id $Id
        $ScriptBlock = $Command.ToScriptBlock()
        $ScriptBlock.Invoke()

    .EXAMPLE
        Pop-QueueCommand -Id $Id -Unshift
        $ScriptBlock = $Command.ToScriptBlock()
        $ScriptBlock.Invoke()
#>
[CmdletBinding()]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
    [ArgumentCompleter( {
            param ( $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters )
            Get-ChildItem -Path "MetaNull:\Queues" | Split-Path -Leaf | Where-Object {$_ -like "$wordToComplete*"}
        } )]
    [guid] $Id,
    
    [Parameter(Mandatory = $false)]
    [switch] $Unshift
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    [System.Threading.Monitor]::Enter($MetaNull.Queue.Lock)
    try {
        # Collect the existing commands
        $Commands = Get-ChildItem "MetaNull:\Queues\$Id\Commands" | Foreach-Object {
            $_ | Get-ItemProperty | Select-Object * | Select-Object -ExcludeProperty PS* | Write-Output
        } | Sort-Object -Property Index

        # Select which command to remove
        if($Unshift.IsPresent -and $Unshift) {
            $Command = $Commands | Select-Object -First 1
        } else {
            $Command = $Commands | Select-Object -Last 1
        }
        if(-not $Command -or -not $Command.Index) {
            return
        }

        # Remove the command from the registry
        Remove-Item -Force -Recurse "MetaNull:\Queues\$Id\Commands\$($Command.Index)"

        # Return the popped/unshifted command
        $Command | Add-Member -MemberType ScriptMethod -Name ToScriptBlock -Value {
            try {
                return [System.Management.Automation.ScriptBlock]::Create($this.Command -join "`n")
            } catch {
                return $null
            }
        }
        $Command | Write-Output
    } finally {
        [System.Threading.Monitor]::Exit($MetaNull.Queue.Lock)
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}