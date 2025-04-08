<#
    .SYNOPSIS
        Escape a string replacing single quotes in an appropriate way
#>
Function Select-EscapeSingleQuotedString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $String
    )
    Process {
        if($String) {
            [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($String)
        }
    }
}