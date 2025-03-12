[CmdletBinding(DefaultParameterSetName = 'IncrementBuild')]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-ModuleDefinition -ModuleDefinitionPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $ModuleDefinitionPath,

    [switch] $IncrementMajor,

    [switch] $IncrementMinor,

    [switch] $IncrementRevision
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $ModulePath = $ModuleDefinitionPath | Split-Path -Parent
        $ScriptPath = Join-Path $ModulePath Build.ps1 -Resolve
        Push-Location (Split-Path $ScriptPath -Parent)
        
        $ScriptArguments = $args | Where-Object { $_ -ne $ModuleDefinitionPath }
        if($ScriptArguments -eq $null) {
            $ScriptArguments = @()
        }
        . $ScriptPath @ScriptArguments

        $ModuleDefinitionPath  | Write-Output
    } finally {
        Pop-Location
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}