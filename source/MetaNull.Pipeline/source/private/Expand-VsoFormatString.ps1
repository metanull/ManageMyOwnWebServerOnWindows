<#
.SYNOPSIS
    Parse a string, checking if it contains fomratting instructions (using Azure DevOps' VSO syntax)

.DESCRIPTION
    Parse a string, checking if it contains fomratting instructions (using Azure DevOps' VSO syntax)

.PARAMETER line
    The string to parse

.EXAMPLE
    # Parse a string
    '##[section]Start of the section' | Expand-VsoFormatString
#>
[CmdletBinding()]
[OutputType([object])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $line
)
Begin {
    $vso_regex = [regex]::new('^##\[(?<format>group|endgroup|section|warning|error|debug|command)\](?<line>.*)$')
}
End {

}
Process {
    # Check if the line is null or empty
    if ([string]::IsNullOrEmpty($line)) {
        return
    }
    # Check if the line is a VSO command
    $vso = $vso_regex.Match($line)
    if (-not ($vso.Success)) {
        # VSO Command not recognized
        return $line
    }
    return @{
        Format  = $vso.Groups['format'].Value
        Message = $vso.Groups['line'].Value
    }
}