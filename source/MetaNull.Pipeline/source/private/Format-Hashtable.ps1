<#
    .SYNOPSIS
        Format a Hashtable

    .PARAMETER Hashtable
        The hashtable to format

    .PARAMETER Format
        The type of format to use (only 'Flat' is currently supported)

    .PARAMETER Prefix
        Used internally, adds a prefix to the Key in recursive function calls
#>
function Format-Hashtable {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        [AllowEmptyCollection()]
        [hashtable]$Hashtable,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Flat')]
        [string]$Format = 'Flat',

        [string]$Prefix = ''
    )
    $result = @{}
    foreach ($key in $Hashtable.Keys) {
        $newKey = if ($Prefix) { "$Prefix.$key" } else { $key }
        if ($Hashtable[$key] -is [hashtable]) {
            $nestedResult = Format-Hashtable -Format $Format -Hashtable $Hashtable[$key] -Prefix $newKey
            foreach ($nestedKey in $nestedResult.Keys) {
                $result[$nestedKey] = $nestedResult[$nestedKey]
            }
        } else {
            $result[$newKey] = $Hashtable[$key]
        }
    }
    return $result
}