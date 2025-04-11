<#
    .SYNOPSIS
        Lookup for valid Queue Names, and provides Auto Completion for partial Names

    .PARAMETER $PartialName
        A partial MEssage Queue Name

    .EXAMPLE
        # Direct use
        $IDs = Resolve-MessageQueueName -PartialName 'Queue*'

    .EXAMPLE
        # Use as a Parameter Argument Completer
        Function MyFunction {
            param(
                [Parameter(Mandatory)]
                [SupportsWildcards()]
                [ArgumentCompleter( {Resolve-MessageQueueName @args} )]
                [string] $Name
            )
            "Autocompleted Name: $Name"
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

Get-ChildItem -Path "MetaNull:\MessageQueue" | Get-ItemProperty | Select-Object -ExpandProperty Name | Where-Object {
    $_ -like $PartialQueueName
}