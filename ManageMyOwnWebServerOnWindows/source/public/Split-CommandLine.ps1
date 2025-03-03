
<#
.SYNOPSIS
Splits a command line into a command and its arguments.
.DESCRIPTION
This function splits a command line into a command and its arguments.
.PARAMETER commandLine
The command line to split.
.EXAMPLE
Split-CommandLine "Get-Process -Name PowerShell"
Returns:
Command    Arguments
-------    ---------
Get-Process { -Name, PowerShell }
.EXAMPLE
Split-CommandLine "C:\apache\bin\httpd.exe -f c:\apache\conf\httpd.conf -k runservice"
Returns:
Command    Arguments
-------    ---------
C:\apache\bin\httpd.exe { -f, c:\apache\conf\httpd.conf, -k, runservice }
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string]$commandLine
)
Process {
    $tokens = [System.Management.Automation.PSParser]::Tokenize($commandLine, [ref]$null)
    return @{
        Command   = $tokens[0].Content
        Arguments = $tokens[1..($tokens.Count - 1)] | ForEach-Object {
            $_.Content
        }
    }
}