<#
    .SYNOPSIS
        Test if a string is a valid VSO command

    .DESCRIPTION
        Test if a string is a valid VSO command

    .PARAMETER String
            The string to test

    .EXAMPLE
        # Test a string
        '##vso[task.complete result=Succeeded;]Task completed successfully' | Test-VisualStudioOnlineString
#>
[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([bool])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $String
)
Process {
    return -not -not (ConvertFrom-VisualStudioOnlineString -String $String)
}