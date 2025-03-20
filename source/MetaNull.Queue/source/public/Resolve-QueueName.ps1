<#
    .SYNOPSIS
        Lookup for valid Queue Names, and provides Auto Completion for partial Names
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
    $PartialName
)

$PartialQueueName = '*'
if($PSCmdlet.ParameterSetName -eq 'ArgumentCompleter') {
    $PartialQueueName = "$wordToComplete*"
} elseif($PSCmdlet.ParameterSetName -eq 'Lookup') {
    $PartialQueueName = "$PartialName"
} else {
    throw "Invalid ParameterSet"
}

Get-ChildItem -Path "MetaNull:\Queues" | Get-ItemProperty | Select-Object -ExpandProperty Name | Where-Object {
    $_ -like $PartialQueueName
}