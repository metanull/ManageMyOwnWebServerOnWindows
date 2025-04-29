<#
    .SYNOPSIS
    Remove a Pipeline from the Registry
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [ArgumentCompleter( { Resolve-PipelineId @args } )]
    [Alias('PipelineId')]
    [guid]
    $Id,

    [Parameter(Mandatory = $false)]
    [switch]
    $Force = $false
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $Force = $Force.IsPresent -and $Force # -or $PSCmdlet.ShouldContinue("Remove Pipeline $Id", "Are you sure?")
        Get-Item "MetaNull:\Pipelines\$Id" | Remove-Item -Recurse -Force:$Force | Out-Null
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}