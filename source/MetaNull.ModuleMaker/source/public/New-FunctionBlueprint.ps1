<#
.SYNOPSIS
    Create a new function in a module created by ModuleMaker

.DESCRIPTION
    This function creates a new function in a module created by ModuleMaker. It creates a new function in the source directory and a new test file in the test directory.

.PARAMETER BlueprintPath
    The path to the module definition file (Blueprint.psd1). This file is created by New-Module and contains the module's metadata.

.PARAMETER Name
    The name of the new function. This name must be a valid Powershell function name.

.PARAMETER Private
    If this switch is present, the function will be created in the private directory. Otherwise, it will be created in the public directory.

.OUTPUTS
    The path to the module definition file (Blueprint.psd1) is returned.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-BlueprintPath -BlueprintPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $BlueprintPath,

    [Parameter(Mandatory)]
    [ValidateScript({
        $_ -match '^[a-zA-Z][a-zA-Z0-9\._-]*$'
    })]
    [string] $Name,

    [Parameter(Mandatory=$false)]
    [switch] $Private
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $DummyName = "Get-Dummy"
        $ModulePath = $BlueprintPath | Split-Path -Parent
        $ResourcePath = Get-BlueprintResourcePath

        $Visibility = if($Private) { 'private' } else { 'public' }
        $TargetSourceDirectory = Join-Path (Join-Path $ModulePath source) $Visibility -Resolve
        $TargetTestDirectory = Join-Path (Join-Path $ModulePath test) $Visibility -Resolve

        $TemplateFunction = Join-Path $ResourcePath "dummy\source\public\$DummyName.ps1" -Resolve
        $TargetFunction = Join-Path $TargetSourceDirectory "$Name.ps1"
        Copy-Item -Path $TemplateFunction -Destination $TargetFunction | Out-Null
        $Content = Get-Content -LiteralPath $TemplateFunction -Raw
        $Content -replace $DummyName, $Name | Set-Content -LiteralPath $TargetFunction
        
        $TemplateTest = Join-Path $ResourcePath "dummy\test\public\$DummyName.Tests.ps1" -Resolve
        $TargetTest = Join-Path $TargetTestDirectory "$Name.Tests.ps1"
        Copy-Item -Path $TemplateTest -Destination $TargetTest | Out-Null
        $Content = Get-Content -LiteralPath $TemplateTest -Raw
        $Content -replace $DummyName, $Name | Set-Content -LiteralPath $TargetTest
    } finally {
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}