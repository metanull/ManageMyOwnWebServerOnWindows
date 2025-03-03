<#
.SYNOPSIS
    Extracts a value from an Apache configuration file.
.DESCRIPTION
    Extracts a value from an Apache configuration file.
.PARAMETER Conf
    The Apache configuration file's contents.
.PARAMETER Statement
    The statement to extract the value from.
.EXAMPLE
    ApacheConfExtractValue -Conf $Conf -Statement "ServerRoot"
    Returns "C:/Apache24" if the Apache configuration file contains "ServerRoot ""C:/Apache24""".
#>
param(
    [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
    $Conf,
    [parameter(Mandatory=$true,Position=1)]
    $Statement
)
Process {
    $Conf | Select-String -Pattern "^\s*$Statement" | Foreach-Object {
        if($_ -match "^\s*$Statement\s+(""?)([^""#]+?)\1\s*(#.*)?$") {
            $Matches[2] | Write-Output
        }
    }
}