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
