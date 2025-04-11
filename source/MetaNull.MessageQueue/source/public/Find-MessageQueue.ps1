<#
.SYNOPSIS
    Find a message queue by Name
.DESCRIPTION
    Find a message queue by Name
.PARAMETER Name
    The name of the message queue
.EXAMPLE
    Find-MessageQueue -Name 'MyQueue'
.EXAMPLE
    Find-MessageQueue -Name 'My*'
.OUTPUTS
    [guid] True if the message queue exists, otherwise false.
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact = 'Low')]
[OutputType([guid],[Object[]])]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline, Position = 0)]
    [ArgumentCompleter( {Resolve-MessageQueueName @args} )]
    [SupportsWildcards()]
    [string]$Name = '*'
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if(-not $Name) {
            $Name = '*'
        }
        Get-Item "MetaNull:\MessageQueue" | Get-ChildItem | Where-Object {
            $_ | Get-ItemProperty | Select-Object -ExpandProperty Name | Where-Object { 
                $_ -like $Name
            }
        } | Select-Object -ExpandProperty PSChildName | ForEach-Object {
            [guid]::new($_)
        }
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}