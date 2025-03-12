#requires -module Microsoft.PowerShell.PSResourceGet -version 1.0
#requires -module Microsoft.PowerShell.SecretManagement
#requires -module Microsoft.PowerShell.SecretStore
[CmdletBinding(DefaultParameterSetName = 'psgallery')]
param(
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
Begin {
    # Set ErrorAction to Stop
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    "Loading the Build Settings" | Write-Verbose
	$Build = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '.\Build.psd1' -Resolve)

    $ModuleVersion = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '.\Version.psd1' -Resolve)
    $ModuleVersion = [version]::new("$($ModuleVersion.Major).$($ModuleVersion.Minor).$($ModuleVersion.Build).$($ModuleVersion.Revision)")

    $ModulePath = Resolve-Path -Path (Join-Path (Join-Path $PSScriptRoot $Build.Destination) ($ModuleVersion.ToString()))
    $ModulePath  | Write-Warning
}
End {
    # Restore ErrorAction
    $ErrorActionPreference = $BackupErrorActionPreference
}
Process {
    # Initialize the Secret Vault, retrieve the SecretInfo and Secret
    "Initialize the Secret Vault" | Write-Verbose
    try {
        $Vault = Get-SecretVault -Name $VaultName
    } catch {
        Register-SecretVault -Name $VaultName -ModuleName Microsoft.PowerShell.SecretStore #-DefaultVault
        $Vault = Get-SecretVault -Name $VaultName
    }

    "Retrieving the SecretInfo" | Write-Verbose
    $SecretInfo = Get-SecretInfo -Vault $Vault.Name -Name $SecretName
    if(($PromptSecret.IsPresent -and $PromptSecret) -or (-not ($SecretInfo))) {
        $Credential = (Get-Credential -UserName 'Personal Access Token' -Message 'Please provide your Personal Access Token for the Repository.')
        #if($PsCmdlet.ParameterSetName -eq 'psgallery') {
        #    Set-Secret -Vault $Vault.Name -Name $SecretName -SecureStringSecret $Credential.Password
        #} else {
            Set-Secret -Vault $Vault.Name -Name $SecretName -Secret $Credential
        #}
        $SecretInfo = Get-SecretInfo -Vault $Vault.Name -Name $SecretName
        if(-not ($SecretInfo)) {
            throw "Error loading SecretInfo for '$SecretName' from the vault"
        }
    }

    "Retrieving the Secret" | Write-Verbose
    $Secret = Get-Secret -Vault $SecretInfo.VaultName -Name $SecretInfo.Name
    if(-not ($Secret)) {
        throw "Error loading the Secret $($SecretInfo.Name) from Vault $($SecretInfo.VaultName)"
    }

    # Select the PSResourceRepository
    if($PsCmdlet.ParameterSetName -eq 'psgallery') {
        $RepositoryName = 'PSGallery'
        $Repository = Get-PSResourceRepository -Name $RepositoryName
    } else {
        $Repository = Get-PSResourceRepository | Where-Object {
            $_.Uri -eq $RepositoryUri
        }
        if(-not ($Repository)) {
            "Registering the custom repository '$RepositoryName' ($RepositoryUri)" | Write-Verbose
            $CredentialInfo = [Microsoft.PowerShell.PSResourceGet.UtilClasses.PSCredentialInfo]::new($VaultName, $SecretName)
            Register-PSResourceRepository -Name $RepositoryName -Uri $RepositoryUri -Trusted -CredentialInfo $CredentialInfo 
            $Repository = Get-PSResourceRepository -Name $RepositoryName
        } else {
            # Update the repository name (as it was already registered)
            $RepositoryName = $Repository.Name
        }
    }
    if(-not ($Repository)) {
        throw "Error selecting the PSResourceRepository '$($RepositoryName)'"
    }

    "Set-PSResourceRepository -Name $($Repository.Name) -Trusted" | Write-Verbose
    Set-PSResourceRepository -Name $($Repository.Name) -Trusted

    # Publish the module to the repository
    try {
        "Publishing $ModulePath to '$($Repository.Name)' ($($Repository.Uri))" | Write-Verbose
        $ApiKey = $null
        if(($PersonalAccessTokenAsString.IsPresent -and $PersonalAccessTokenAsString) -or $PsCmdlet.ParameterSetName -eq 'psgallery') {
            # PSGallery and some repositories require the PAT token to be a clear text string
            if($SecretInfo.Type -eq [Microsoft.PowerShell.SecretManagement.SecretType]::PSCredential) {
                $ApiKey = (Get-Secret -Vault $SecretInfo.VaultName -Name $SecretInfo.Name).GetNetworkCredential().Password
            } elseif($SecretInfo.Type -eq [Microsoft.PowerShell.SecretManagement.SecretType]::SecureString) {
                $ApiKey = (Get-Secret -Vault $SecretInfo.VaultName -Name $SecretInfo.Name -AsPlainText)
            } elseif($SecretInfo.Type -eq [Microsoft.PowerShell.SecretManagement.SecretType]::String) {
                $ApiKey = (Get-Secret -Vault $SecretInfo.VaultName -Name $SecretInfo.Name -AsPlainText)
            } else {
                throw "Unable to handle Secret from the vault, as it is of an unexpected '$($SecretInfo.Type)' type. Consider -PromptSecret to replace the current secret."
            }
        } else {
            # Other repositories (e.g. Azure DevOps' Artefact Stream accept PAT as a [PSCredential]
            $ApiKey = (Get-Secret -Vault $SecretInfo.VaultName -Name $SecretInfo.Name)
        }
        Publish-PSResource -Path $ModulePath -Repository ($Repository.Name) -ApiKey ($ApiKey)
    } finally {
        # Remove the ApiKey variable, as it may contain the clear text PAT
        Remove-Variable -Name ApiKey -Force -ErrorAction SilentlyContinue
    }
}