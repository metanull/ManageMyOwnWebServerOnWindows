[CmdletBinding(DefaultParameterSetName='Pester')]
param(
    [Parameter(Mandatory,ValueFromPipeline)]
    [ValidateScript({
        Test-BlueprintPath -BlueprintPath $_
    })]
    [Alias('Path','DataFile')]
    [string] $BlueprintPath,

    # Pester
    [Parameter(Mandatory,ParameterSetName='Pester')]
    [switch] $InvokeTest,

    # Build
    [Parameter(Mandatory,ParameterSetName='Build')]
    [switch] $InvokeBuild,

    [Parameter(Mandatory,ParameterSetName='Build')]
    [switch] $IncrementMajor,

    [Parameter(Mandatory,ParameterSetName='Build')]
    [switch] $IncrementMinor,

    [Parameter(Mandatory,ParameterSetName='Build')]
    [switch] $IncrementRevision,

    # Publish
    [Parameter(Mandatory,ParameterSetName='Publish')]
    [switch] $InvokePublish,

    [Parameter(Mandatory = $false,ParameterSetName='Publish')]
    [string] $RepositoryName = 'PSGallery',

    [Parameter(Mandatory,ParameterSetName='Publish')]
    [System.Management.Automation.Credential()]
    [System.Management.Automation.PSCredential]
    $Credential
)
Process {
    $BackupErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    Push-Location (Split-Path $ScriptPath -Parent)
    try {
        $ModulePath = $BlueprintPath | Split-Path -Parent

        if($InvokeTest) {
            # Invoke the Unit Tests
            Invoke-Pester -Path .\test -OutputFile .\testresults.xml -OutputFormat NUnitXml -CodeCoverageOutputFile .\coverage.xml -PassThru
        } elseif($InvokeBuild) {
            # Invoke the Build script
            $ScriptPath = Join-Path $ModulePath Build.ps1 -Resolve
            $ScriptArguments = $args | Where-Object { $_ -ne $BlueprintPath }
            if($ScriptArguments -eq $null) {
                $ScriptArguments = @()
            }
            . $ScriptPath @ScriptArguments
        } elseif($InvokePublish) {
            # Invoke the Publish script
            $ScriptArguments = $args | Where-Object { $_ -ne $BlueprintPath }
            if($ScriptArguments -eq $null) {
                $ScriptArguments = @()
            }
            . $ScriptPath @ScriptArguments
        }

    } finally {
        Pop-Location
        $ErrorActionPreference = $BackupErrorActionPreference
    }
}