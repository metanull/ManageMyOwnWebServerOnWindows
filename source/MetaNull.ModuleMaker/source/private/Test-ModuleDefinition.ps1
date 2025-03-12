[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [AllowNull()]
    [Alias('Path','DataFile')]
    [string] $ModuleDefinitionPath
)
End {
    $EAB = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Stop'
        if(-not $ModuleDefinitionPath) {
            Write-Debug "Module definition path is null, empty or not provided"
            return $false
        }
        if(-not (Test-Path -Path $ModuleDefinitionPath -PathType Leaf)) {
            Write-Debug "Module definition file does not exist or is not a file, for path: $ModuleDefinitionPath"
            return $false
        }

        Write-Debug "Importing Module definition from: $ModuleDefinitionPath"
        $ModuleDefinition = Import-PowerShellDataFile -Path $ModuleDefinitionPath

        if($null -eq $ModuleDefinition.Name -or $null -eq $ModuleDefinition.ModuleSettings -or $null -eq $ModuleDefinition.ModuleSettings.GUID) {
            Write-Debug "Module definition is invalid: `$_.Name or `$_.GUID are missing"
            return $false
        }
        if($ModuleDefinition.Name -eq '%%MODULE_NAME%%' -or $ModuleDefinition.ModuleSettings.GUID -eq '%%MODULE_GUID%%') {
            Write-Debug "Module definition is invalid: `$_.Name or `$_.GUID are not initialized"
            return $false
        }
        if($ModuleDefinition.Name -eq [string]::empty -or $ModuleDefinition.ModuleSettings.GUID -eq [string]::empty) {
            Write-Debug "Module definition is invalid: `$_.Name or `$_.GUID are empty"
            return $false
        }
        
        Write-Debug "Module definition is valid. Module: $($ModuleDefinition.Name)"
        
        $ModulePath = $ModuleDefinitionPath | Split-Path -Parent
        Write-Debug "Testing Module structure from: $ModulePath"
        if(-not (Test-Path -Path (Join-Path $ModulePath source) -PathType Container)) {
            Write-Debug "Module source directory does not exist"
            return $false
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath test) -PathType Container)) {
            Write-Debug "Module test directory does not exist"
            return $false
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath Build.ps1) -PathType Leaf)) {
            Write-Debug "Module's Build script does not exist"
            return $false
        }
        if(-not (Test-Path -Path (Join-Path $ModulePath Publish.ps1) -PathType Leaf)) {
            Write-Debug "Module's Publish script does not exist"
            return $false
        }

        Write-Debug "Module structure is valid. Path: $($ModulePath)"

        return $true
    } catch {
        Write-Verbose "$($_.Exception.Message)"
        # Swallow exception, to permit returninbg $false instead of throwing
    } finally {
        $ErrorActionPreference = $EAB
    }
    return $false
}