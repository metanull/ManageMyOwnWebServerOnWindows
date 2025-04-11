﻿<#
    .SYNOPSIS
        Lookup for valid Message Queue Ids, and provides Auto Completion for partial Ids

    .PARAMETER $PartialId
        A partial Message Queue ID

    .EXAMPLE
        # Direct use
        $IDs = Resolve-MessageQueueId -PartialId '123*'

    .EXAMPLE
        # Use as a Parameter Argument Completer
        Function MyFunction {
            param(
                [Parameter(Mandatory)]
                [SupportsWildcards()]
                [ArgumentCompleter( {Resolve-MessageQueueId @args} )]
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

$PartialQueueId = '*'
if($PSCmdlet.ParameterSetName -eq 'ArgumentCompleter') {
    $PartialQueueId = "$wordToComplete*"
} elseif($PSCmdlet.ParameterSetName -eq 'Lookup') {
    $PartialQueueId = "$PartialId"
} else {
    throw "Invalid ParameterSet"
}
Get-ChildItem -Path "MetaNull:\MessageQueue" | Split-Path -Leaf | Where-Object {
    $_ -like $PartialQueueId
}
