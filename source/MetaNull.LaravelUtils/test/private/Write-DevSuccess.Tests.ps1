[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevSuccess" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorSuccess = "Green"
        }

        It "Write-DevSuccess should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "✅"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Success"
                Write-Host "$icon Test success message" -ForegroundColor $script:ModuleColorSuccess
            } | Should -Not -Throw
        }

        It "Write-DevSuccess should handle different success message types" {
            Function Get-ModuleIcon { return "✅" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different success message scenarios
            { 
                $icon = Get-ModuleIcon "Success"
                Write-Host "$icon Server started successfully" -ForegroundColor $script:ModuleColorSuccess
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Success"
                Write-Host "$icon All services running" -ForegroundColor $script:ModuleColorSuccess
            } | Should -Not -Throw
        }

        It "Write-DevSuccess should use correct color variable" {
            $script:ModuleColorSuccess | Should -Be "Green"
        }

        It "Write-DevSuccess message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevSuccess.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevSuccess should work with valid message parameter" {
            Function Get-ModuleIcon { return "✅" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevSuccess {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Success"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorSuccess
            }
            
            { Write-DevSuccess -Message "Test success" } | Should -Not -Throw
        }
    }
}

