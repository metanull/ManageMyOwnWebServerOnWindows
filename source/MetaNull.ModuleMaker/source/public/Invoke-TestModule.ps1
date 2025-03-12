[CmdletBinding()]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-ModuleDefinition -ModuleDefinitionPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $ModuleDefinitionPath
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $ModulePath = $ModuleDefinitionPath | Split-Path -Parent
        $ScriptPath = Join-Path $ModulePath Build.ps1 -Resolve
        Push-Location (Split-Path $ScriptPath -Parent)
        
        Invoke-Pester -Path . -OutputFile .\testresults.xml -OutputFormat NUnitXml -CodeCoverageOutputFile .\coverage.xml -PassThru

        $ModuleDefinitionPath  | Write-Output
    } finally {
        Pop-Location
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}