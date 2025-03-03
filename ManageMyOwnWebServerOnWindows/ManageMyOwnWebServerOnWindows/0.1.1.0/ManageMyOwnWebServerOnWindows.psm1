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
Function ApacheConfExtractValue {
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        $Conf,
        [parameter(Mandatory=$true,Position=1)]
        $Statement
    )
    $Conf | Select-String -Pattern "^\s*$Statement" | Foreach-Object { 
        if($_ -match "^\s*$Statement\s*("")?(.*?)\1") {
            $Matches[2] | Write-Output
        }
    }
}
}
Function ApacheConfExtractValuePair {
Function ApacheConfExtractValuePair {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        $Conf,
        [parameter(Mandatory=$true,Position=1)]
        $Statement
    )
    $Conf | Select-String "^\s*$Statement" | Foreach-Object { 
        if($_ -match "^\s*$Statement\s*(.*?)\s*("")?(.*?)\2") {
            @{
                $Matches[1]=$Matches[3]
            } | Write-Output
        }
    }
}
}
Function ApacheConfReplaceConstant {
Function ApacheConfReplaceConstant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        $Value,
        [Parameter(Mandatory=$true,Position=1)]
        $Constants
    )
    while($Value -match '\$\{(.*?)\}') {
        if (-not $Constants.ContainsKey($Matches[1])) {
            break
        }
        $Value = $Value.Replace($Matches[0],$Constants[$Matches[1]])
    }
    $Value | Write-Output
}
}
Function ApacheConfResolvePath {
Function ApacheConfResolvePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [AllowNull()]
        $Path,
        [Parameter(Mandatory=$true,Position=1)]
        $ServerRoot
    )
    if(-not $Path) {
        return $null
    }
    if(-not ([System.IO.Path]::IsPathRooted($Path))) {
        Join-Path $ServerRoot $Path | Write-Output
    } else {
        $Path | Write-Output
    }
}
}
Function Get-ApacheService {
Function Get-ApacheService {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
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
            if(-not (Test-IsAdministrator)) {
                throw "You must be an administrator to call this function"
            }

            # Find the Apache Service (if not specified)
            if(-not $Name) {
                $Apache = Get-Service -DisplayName '*apache*'
                if($Apache.Count -gt 1) {
                    throw "Multiple Apache services found: '$($Apache.Name -join "', '")', use -Name to specify which one to use"
                }
                $Name = $Apache.Name
            }
        
            # Get details of the Apache service
            $ServiceWMI = (Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $Name })
            if($null -eq $ServiceWMI) {
                throw "No $Name service found"
            }
            $ServiceCommand = $ServiceWMI.PathName | Split-CommandLine

            # Find the Apache executable
            $Httpd = Get-Command $ServiceCommand.Command
            
            # Find the Apache configuration file's location
            $HttpdConfPath = Join-Path (Split-Path -Parent $ServiceCommand.Command) '..\conf\httpd.conf'
            for($i = 0; $i -lt ($ServiceCommand.Arguments.Count - 1); $i++) {
                if($ServiceCommand.Arguments[$i] -eq '-f') {
                    $HttpdConfPath = $ServiceCommand.Arguments[$i+1]
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
                Service = $ServiceWMI
                Binary = $Httpd.Source
                Version = $Httpd.Version
                HttpdConf = $HttpdConfPath
                ServerRoot = $HttpdServerRoot
                ErrorLog = $HttpdErrorLog
                AccessLog = $HttpdAccessLog
                PhpIniDir = $PhpIniDir
                Constants = $HttpdConstants
            }
        } finally {
            $ErrorActionPreference = $SavedErrorActionPreference
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
Function Test-IsAdministrator {
	[CmdletBinding()]
	[OutputType([bool])]
    param()
    Process {
	    (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) | Write-Output
    }
}
}
Function Test-ServerSideSetup {
}
