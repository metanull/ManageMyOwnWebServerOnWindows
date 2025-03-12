# Module Constants

Set-Variable MOWOW -option Constant -Description 'Constants of the ManageMyOwnWebServerOnWindows Module' -Value @{
    Registry = @{
        # Registry Path
        Path = 'HKLM:\SOFTWARE\ManageMyOwnWebServerOnWindows'
        # Registry Key
        Key = 'Settings'
        # Registry Value
        Value = @{
            # HTTPD binary path
            Httpd = ''
            # HTTPD configuration path
            HttpdConf = ''
            # PHP binary path
            Php = ''
            # PHP configuration path
            PhpIni = ''
            # NodeJS binary path
            Node = ''
        }
    }
}
Function ApacheConfExtractValue {
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
    [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    $Conf,
    [parameter(Mandatory = $true, Position = 1)]
    $Statement
)
Process {
    $Conf | Select-String -Pattern "^\s*$Statement" | Foreach-Object {
        if ($_ -match "^\s*$Statement\s+(""?)([^""#]+?)\1\s*(#.*)?$") {
            $Matches[2] | Write-Output
        }
    }
}
}
Function ApacheConfExtractValuePair {
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
}
Function ApacheConfReplaceConstant {
<#
.SYNOPSIS
    Replace constant in Apache configuration file.
.DESCRIPTION
    Replace constant in Apache configuration file.
.PARAMETER Value
    The value to replace the constants in.
.PARAMETER Constants
    The constants to replace in the value.
.EXAMPLE
    ApacheConfReplaceConstant -Value "${SRVROOT}/conf/httpd.conf" -Constants @{ SRVROOT = "C:/Apache24" }
    Returns "C:/Apache24/conf/httpd.conf".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    $Value,
    [Parameter(Mandatory = $true, Position = 1)]
    $Constants
)
Process {
    while ($Value -match '\$\{(.*?)\}') {
        if (-not $Constants.ContainsKey($Matches[1])) {
            break
        }
        $Value = $Value.Replace($Matches[0], $Constants[$Matches[1]])
    }
    $Value | Write-Output
}
}
Function ApacheConfResolvePath {
<#
.SYNOPSIS
    Resolves a path in an Apache configuration file.
.DESCRIPTION
    Resolves a path in an Apache configuration file.
.PARAMETER Path
    The path to resolve.
.PARAMETER ServerRoot
    The Apache server root.
.EXAMPLE
    ApacheConfResolvePath -Path "conf/httpd.conf" -ServerRoot "C:/Apache24"
    Returns "C:/Apache24/conf/httpd.conf".
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [AllowNull()]
    $Path,
    [Parameter(Mandatory = $true, Position = 1)]
    $ServerRoot
)
Process {
    if (-not $Path) {
        return $null
    }
    if (-not ([System.IO.Path]::IsPathRooted($Path))) {
        Join-Path $ServerRoot $Path | Write-Output
    }
    else {
        $Path | Write-Output
    }
}
}
Function Get-ApacheService {
<#
.SYNOPSIS
    Get details of the Apache service running on the local machine.
.DESCRIPTION
    Get details of the Apache service running on the local machine.
.PARAMETER Name
    The name of the Apache service to get details of.
.EXAMPLE
    Get-ApacheService
    Returns details of the Apache service running on the local machine.
.EXAMPLE
    Get-ApacheService -Name "Apache2.4"
    Returns details of the Apache2.4 service running on the local machine.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
    [Alias('Service')]
    [String]$Name = $null
)
Begin {
    $SavedErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
}
Process {
    try {
        # Check if the user is an administrator
        if (-not (Test-IsAdministrator)) {
            throw "You must be an administrator to call this function"
        }

        # Find the Apache Service (if not specified)
        if (-not $Name) {
            $Apache = Get-Service -DisplayName '*apache*'
            if ($Apache.Count -gt 1) {
                throw "Multiple Apache services found: '$($Apache.Name -join "', '")', use -Name to specify which one to use"
            }
            $Name = $Apache.Name
        }

        # Get details of the Apache service
        $ServiceWMI = (Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $Name })
        if ($null -eq $ServiceWMI) {
            throw "No $Name service found"
        }
        $ServiceCommand = $ServiceWMI.PathName | Split-CommandLine

        # Find the Apache executable
        $Httpd = Get-Command $ServiceCommand.Command

        # Find the Apache configuration file's location
        $HttpdConfPath = Join-Path (Split-Path -Parent $ServiceCommand.Command) '..\conf\httpd.conf'
        for ($i = 0; $i -lt ($ServiceCommand.Arguments.Count - 1); $i++) {
            if ($ServiceCommand.Arguments[$i] -eq '-f') {
                $HttpdConfPath = $ServiceCommand.Arguments[$i + 1]
                break
            }
        }
        $HttpdConf = Resolve-Path $HttpdConfPath | Get-Content

        # Extract the constants from the Apache configuration file
        $HttpdConstants = $HttpdConf | ApacheConfExtractValuePair -Statement 'Define'

        # Extract the primary ServerRoot from the Apache configuration file
        $HttpdServerRoot = $HttpdConf | ApacheConfExtractValue -Statement 'ServerRoot' | Select-Object -First 1 | ApacheConfReplaceConstant -Constants $HttpdConstants | Resolve-Path

        # Extract the access and error logs from the Apache configuration file
        $HttpdErrorLog = $HttpdConf | ApacheConfExtractValue -Statement 'ErrorLog' | ForEach-Object {
            $_ | ApacheConfReplaceConstant -Constants $HttpdConstants | ApacheConfResolvePath -ServerRoot $HttpdServerRoot
        }

        # Extract the access and error logs from the Apache configuration file
        $HttpdAccessLog = $HttpdConf | ApacheConfExtractValue -Statement 'CustomLog' | ForEach-Object {
            $_ | ApacheConfReplaceConstant -Constants $HttpdConstants | ApacheConfResolvePath -ServerRoot $HttpdServerRoot
        }

        # Extract the PHPIniDir (if any) from the Apache configuration file
        $PhpIniDir = $HttpdConf | ApacheConfExtractValue -Statement 'PHPIniDir' | Select-Object -First 1 | ApacheConfReplaceConstant -Constants $HttpdConstants | ApacheConfResolvePath -ServerRoot $HttpdServerRoot

        @{
            Service    = $ServiceWMI
            Binary     = $Httpd.Source
            Version    = $Httpd.Version
            HttpdConf  = $HttpdConfPath
            ServerRoot = $HttpdServerRoot
            ErrorLog   = $HttpdErrorLog
            AccessLog  = $HttpdAccessLog
            PhpIniDir  = $PhpIniDir
            Constants  = $HttpdConstants
        }
    }
    finally {
        $ErrorActionPreference = $SavedErrorActionPreference
    }
}
}
Function Split-CommandLine {

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
}
Function Test-IsAdministrator {
<#
.SYNOPSIS
    Test if the current user is an administrator.
.DESCRIPTION
    Test if the current user is an administrator.
.EXAMPLE
    Test-IsAdministrator
    Returns True if the current user is an administrator, False otherwise.
#>

[CmdletBinding()]
[OutputType([bool])]
param()
Process {
    (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
}
}
Function Test-ServerSideSetup {
}
