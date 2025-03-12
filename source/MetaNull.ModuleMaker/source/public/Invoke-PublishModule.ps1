[CmdletBinding(DefaultParameterSetName = 'psgallery')]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-ModuleDefinition -ModuleDefinitionPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $ModuleDefinitionPath,

    [Parameter(Mandatory = $false)]
    [string] $RepositoryName = 'PSGallery',

    [Parameter(Mandatory)]
    [System.Management.Automation.Credential()]
    [System.Management.Automation.PSCredential]
    $Credential
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        $ModulePath = $ModuleDefinitionPath | Split-Path -Parent
        $ScriptPath = Join-Path $ModulePath Publish.ps1 -Resolve
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