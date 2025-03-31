<#
    .SYNOPSIS
    Test existance of a Step from a Pipeline
#>
[CmdletBinding()]
[OutputType([bool])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
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
        return Test-Path "MetaNull:\Pipelines\$IdFilter"
    } finally {
        $ErrorActionPreference = $ErrorActionPreferenceBackup
    }
}