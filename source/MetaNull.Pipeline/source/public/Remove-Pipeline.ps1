<#
    .SYNOPSIS
    Remove a Pipeline from the Registry
#>
[CmdletBinding()]
[OutputType([void])]
param(
    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('PipelineId')]
    [SupportsWildcards()]
    [ArgumentCompleter( { Resolve-PipelineId @args } )]
    [Alias('PipelineId')]
    [guid]
    $Id
)
Process {
    $ErrorActionPreferenceBackup = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $IdFilter = '*'
        if ($Id -ne [guid]::Empty) {
            $IdFilter = $Id.ToString()
        }
        Get-Item "MetaNull:\Pipelines\$IdFilter" | Remove-Item -Recurse | Out-Null
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}