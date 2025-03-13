[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [AllowNull()]
    [Alias('Path','DataFile')]
    [string] $BlueprintPath
)
End {
    $EAB = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if(-not $BlueprintPath) {
            throw "Blueprint path is null, empty or not provided"
        }
        if(-not (Test-Path -Path $BlueprintPath -PathType Leaf)) {
            throw "Blueprint file does not exist or is not a file, for path: $BlueprintPath"
        }
        $BlueprintPath = Resolve-Path $BlueprintPath
        if(-not ((Split-Path $BlueprintPath -Leaf) -eq 'Blueprint.psd1' )) {
            throw "Blueprint filename is not compliant (expecting Blueprint.psd1), for path: $BlueprintPath"
        }

        Write-Debug "Importing Blueprint from: $BlueprintPath"
        $ModuleDefinition = Import-PowerShellDataFile -Path $BlueprintPath

        if($null -eq $ModuleDefinition.Name -or $null -eq $ModuleDefinition.ModuleSettings -or $null -eq $ModuleDefinition.ModuleSettings.GUID) {
            throw "Blueprint is invalid: `$_.Name or `$_.GUID are missing"
        }
        if($ModuleDefinition.Name -eq '%%MODULE_NAME%%' -or $ModuleDefinition.ModuleSettings.GUID -eq '%%MODULE_GUID%%') {
            throw "Blueprint is invalid: `$_.Name or `$_.GUID are not initialized"
        }
        if($ModuleDefinition.Name -eq [string]::empty -or $ModuleDefinition.ModuleSettings.GUID -eq [string]::empty) {
            throw "Blueprint is invalid: `$_.Name or `$_.GUID are empty"
        }
        
        $ModulePath = $BlueprintPath | Split-Path -Parent
        if(-not (Test-Path -Path (Join-Path $ModulePath source) -PathType Container)) {
            throw "Module source directory does not exist"
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath test) -PathType Container)) {
            throw "Module test directory does not exist"
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath Build.ps1) -PathType Leaf)) {
            throw "Module's Build script does not exist"
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath Publish.ps1) -PathType Leaf)) {
            throw "Module's Publish script does not exist"
        }

        return $true
    } catch {
        Write-Verbose "$($_.Exception.Message)"
        # Swallow exception, to permit returninbg $false instead of throwing
    } finally {
        $ErrorActionPreference = $EAB
    }
    return $false
}