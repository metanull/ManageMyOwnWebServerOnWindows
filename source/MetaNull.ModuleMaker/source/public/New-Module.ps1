<#
    .SYNOPSIS
        Create an empty Powershell Module

    .EXAMPLE
        $Module = New-Module -Path $env:TEMP -Name MyModule
        $Module | New-Function -Public -Name Get-Something
        $Module | New-Test -Public -Name Get-Something
        $Module | Invoke-Build
        $Module | Invoke-Publish

#>
[CmdletBinding(DefaultParameterSetName)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [ValidateScript({
        Test-Path -Path $_ -PathType Container
    })]
    [Alias('Path')]
    [string] $LiteralPath,

    [Parameter(Mandatory)]
    [ValidateScript({
        $_ -match '^[a-zA-Z][a-zA-Z0-9._-]*$'
    })]
    [string] $Name,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Description = $null,

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [ValidateScript({
        try {
            if($null -eq $_ -or [string]::empty -eq $_ -or [System.Uri]::new($_)) {
                return $true
            }
        } catch {
            # Swallow exception
        }
        return $false
    })]
    [string] $Uri = 'https://www.test.com/mymodule',

    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Author = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),
    
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Vendor = 'Unknown',
    
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [string] $Copyright = "© $((Get-Date).Year). All rights reserved",
    
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [string[]] $ModuleDependencies,
    
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyCollection()]
    [string[]] $AssemblyDependencies,

    [Parameter(Mandatory = $false)]
    [switch] $Force

)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $NewItemForce = $false
        if(Test-JoinPath -Path $LiteralPath -Name $Name) {
            if($Force.IsPresent -and $Force) {
                "Target directory $DirectoryPath exists, overwriting." | Write-Warning
                $NewItemForce = $true
            } else {
                throw "Target directory $DirectoryPath exists"
            }
        }
        # Create the directories
        $RootDirectory = New-Item -Path $LiteralPath -Name $Name -ItemType Directory -Force:$NewItemForce
        $SourceDirectory = New-Item (Join-Path $RootDirectory source) -ItemType Directory -Force:$NewItemForce
        $TestDirectory = New-Item (Join-Path $RootDirectory test) -ItemType Directory -Force:$NewItemForce
        $SourcePublicDirectory = New-Item (Join-Path $SourceDirectory public) -ItemType Directory -Force:$NewItemForce
        $SourcePrivateDirectory = New-Item (Join-Path $SourceDirectory private) -ItemType Directory -Force:$NewItemForce
        $SourceInitDirectory = New-Item (Join-Path $SourceDirectory init) -ItemType Directory -Force:$NewItemForce
        $TestPublicDirectory = New-Item (Join-Path $TestDirectory public) -ItemType Directory -Force:$NewItemForce
        $TestPrivateDirectory = New-Item (Join-Path $TestDirectory private) -ItemType Directory -Force:$NewItemForce

        # Create the module's configuration file, script files, and module's sample source and test files
        if((Get-Variable INSIDE_MODULEMAKER_MODULE -ErrorAction SilentlyContinue)) {
            #INSIDE_MODULEMAKER_MODULE is a constant defined in the module
            #If it is set, then the script is run from a loaded module, PSScriptRoot = Directory of the psm1
            $ResourceDirectory = Get-Item (Join-Path $PSScriptRoot resource)
        } else {
            #Otherwise, the script was probably called from the command line, PSScriptRoot = Directory /source/private
            $ResourceDirectory = Get-Item (Join-Path (Split-Path (Split-Path $PSScriptRoot)) resource)
        }
        Copy-Item $ResourceDirectory\script\*.ps1 $RootDirectory -Force:$NewItemForce
        Copy-Item $ResourceDirectory\data\*.psd1 $RootDirectory -Force:$NewItemForce
        Copy-Item -Path $ResourceDirectory\dummy\* -Destination $SourceDirectory -Recurse -Force:$NewItemForce

        # Update Module's configuration
        $ManifestFile = Get-Item (Join-Path $RootDirectory Build.psd1)
        $ManifestFileContent = Get-Content -LiteralPath $ManifestFile
        $Replace = @{
            '%%MODULE_GUID%%'= (New-Guid)
            '%%MODULE_NAME%%' = "$Name"
            '%%MODULE_DESCRIPTION%%' = "$Description"
            '%%MODULE_URI%%' = "$Uri"
            '%%MODULE_AUTHOR%%' = "$Author"
            '%%MODULE_VENDOR%%'= "$Vendor"
            '%%MODULE_COPYRIGHT%%' = "$Copyright"
            "%%ASSEMBLY_DEPENDENCIES%%" = $null
            "%%MODULE_DEPENDENCIES%%" = $null
        }
        if($AssemblyDependencies) {
            $Replace += @{"%%ASSEMBLY_DEPENDENCIES%%" = "'$($AssemblyDependencies -join "','")'"}
        }
        if($ModuleDependencies) {
            $Replace += @{"%%MODULE_DEPENDENCIES%%" = "'$($ModuleDependencies -join "','")'"}
        }
        $Replace.GetEnumerator() | Foreach-Object {
            if($_.Value) {
                $ManifestFileContent = $ManifestFileContent -replace "$($_.Key)","$($_.Value)"
            } else {
                $ManifestFileContent = $ManifestFileContent -replace "$($_.Key)"
            }
        }
        $ManifestFileContent | Set-Content -LiteralPath $ManifestFile -Force:$NewItemForce
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}