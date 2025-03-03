<#
.SYNOPSIS
    Extracts a value pair from an Apache configuration file.
.DESCRIPTION
    Extracts a value pair from an Apache configuration file.
.PARAMETER Conf
    The Apache configuration file's contents.
.PARAMETER Statement
    The statement to extract the value pair from.
.EXAMPLE
    ApacheConfExtractValuePair -Conf $Conf -Statement "ServerRoot"
    Returns @{ ServerRoot = "C:/Apache24" } if the Apache configuration file contains "ServerRoot ""C:/Apache24""".
#>
[CmdletBinding()]
param(
    [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    $Conf,
    [parameter(Mandatory = $true, Position = 1)]
    $Statement
)
Process {
    $Conf | Select-String "^\s*$Statement" | Foreach-Object {
        if ($_ -match "^\s*$Statement\s+(.*?)\s+(""?)([^""#]+?)\2\s*(#.*)?$") {
            @{
                $Matches[1] = $Matches[3]
            } | Write-Output
        }
    }
}