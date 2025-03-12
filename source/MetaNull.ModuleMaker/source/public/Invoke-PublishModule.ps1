[CmdletBinding(DefaultParameterSetName = 'psgallery')]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-ModuleDefinition -ModuleDefinitionPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $ModuleDefinitionPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'custom')]
    [string] $RepositoryUri,

    [Parameter(Mandatory = $true, ParameterSetName = 'custom')]
    [string] $RepositoryName,

    [Parameter(Mandatory = $false)]
    [string] $VaultName = 'MySecretVault',

    [Parameter(Mandatory = $false)]
    [string] $SecretName = 'PSGalleryCredential',

    [Parameter(Mandatory = $false)]
    [Switch] $PromptSecret,

    [Parameter(Mandatory = $false)]
    [Switch] $PersonalAccessTokenAsString
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