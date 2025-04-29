<#
    .SYNOPSIS
        Lookup for valid Pipeline Ids, and provides Auto Completion for partial Ids

    .PARAMETER $PartialId
        A partial Pipeline ID

    .EXAMPLE
        # Direct use
        $IDs = Resolve-PipelineId -PartialId '123*'

    .EXAMPLE
        # Use as a Parameter Argument Completer
        Function MyFunction {
            param(
                [Parameter(Mandatory)]
                [SupportsWildcards()]
                [ArgumentCompleter( {Resolve-PipelineId @args} )]
                [guid] $Id = [guid]::Empty,
            )
            "Autocompleted ID: $Id"
        }
#>
[CmdletBinding(DefaultParameterSetName = 'ArgumentCompleter')]
param (
    [Parameter(Mandatory,ParameterSetName = 'ArgumentCompleter')]
    $commandName,

    [Parameter(Mandatory,ParameterSetName = 'ArgumentCompleter')]
    $parameterName,

    [Parameter(Mandatory,ParameterSetName = 'ArgumentCompleter')]
    $wordToComplete,

    [Parameter(Mandatory,ParameterSetName = 'ArgumentCompleter')]
    $commandAst,

    [Parameter(Mandatory,ParameterSetName = 'ArgumentCompleter')]
    $fakeBoundParameters,

    [Parameter(Mandatory,ParameterSetName = 'Lookup')]
    [SupportsWildcards()]
    $PartialId
)

$PartialPipelineId = '*'
if($PSCmdlet.ParameterSetName -eq 'ArgumentCompleter') {
    $PartialPipelineId = "$wordToComplete*"
} elseif($PSCmdlet.ParameterSetName -eq 'Lookup') {
    $PartialPipelineId = "$PartialId"
} else {
    throw "Invalid ParameterSet"
}
Get-ChildItem -Path "MetaNull:\Pipelines" | Split-Path -Leaf | Where-Object {
    $_ -like $PartialPipelineId
}
