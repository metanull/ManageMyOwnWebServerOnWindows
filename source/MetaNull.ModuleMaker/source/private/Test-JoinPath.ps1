<#
    .SYNOPSIS
        Test if the output of Join-Path exists

    .EXAMPLE
        Test-JoinPath -Path $env:TEMP -Name toto

    .EXAMPLE
        JoinPath -Path $env:TEMP -Name toto | Test-JoinPath
#>
[CmdletBinding(DefaultParameterSetName = 'LiteralPathAny')]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory,Position=0,ValueFromPipeline,ParameterSetName = 'LiteralPathAny')]
    [Parameter(Mandatory,Position=0,ValueFromPipeline,ParameterSetName = 'LiteralPathDirectory')]
    [Parameter(Mandatory,Position=0,ValueFromPipeline,ParameterSetName = 'LiteralPathFile')]
    [string]
    $LiteralPath,

    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathAny')]
    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathDirectory')]
    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathFile')]
    [string]
    $Path,
    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathAny')]
    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathDirectory')]
    [Parameter(Mandatory,Position=0,ParameterSetName = 'PathFile')]
    [string]
    $Name,

    [Parameter(Mandatory,Position=1,ParameterSetName = 'PathDirectory')]
    [Parameter(Mandatory,Position=1,ParameterSetName = 'LiteralPathDirectory')]
    [switch]
    $Directory,

    [Parameter(Mandatory,Position=1,ParameterSetName = 'PathFile')]
    [Parameter(Mandatory,Position=1,ParameterSetName = 'LiteralPathFile')]
    [switch]
    $File

)
Process {
    if($Directory.IsPresent -and $Directory) {
        $PathType = 'Container'
    } elseif($File.IsPresent -and $File) {
        $PathType = 'Container'
    } else {
        $PathType = 'Any'
    }

    if($PsCmdlet.ParameterSetName -in 'LiteralPathAny','LiteralPathDirectory','LiteralPathFile') {
        return Test-Path -LiteralPath $LiteralPath -PathType $PathType
    } else {
        return Test-Path -LiteralPath (Join-Path -Path $Path -ChildPath $Name) -PathType $PathType
    }
}