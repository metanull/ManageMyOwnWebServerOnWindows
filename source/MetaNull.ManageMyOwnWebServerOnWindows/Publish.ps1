#requires -module Microsoft.PowerShell.PSResourceGet -version 1.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [Alias('NuGetApiKey')]
    [string] $ApiKey
)
Begin {
    # 1. Load the Build Settings
	$Build = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '.\Build.psd1' -Resolve -ErrorAction 'Stop')

    $ModuleVersion = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '.\Version.psd1' -Resolve -ErrorAction 'Stop') -ErrorAction Stop
    $ModuleVersion = [version]::new("$($ModuleVersion.Major).$($ModuleVersion.Minor).$($ModuleVersion.Build).$($ModuleVersion.Revision)")

    $ModulePath = Resolve-Path -Path (Join-Path (Join-Path $PSScriptRoot $Build.Destination) ($ModuleVersion.ToString()) -ErrorAction Stop)
    $ModulePath  | Write-Warning
}
Process {
    Publish-PSResource -Path $ModulePath -Repository PSGallery -ApiKey $ApiKey -ErrorAction Stop
}