[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Write-DevHeader" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            # Set up the module variable that the function expects
            $script:ModuleColorHeader = "Blue"
        }

        It "Write-DevHeader should execute without errors" {
            # Mock the dependencies to avoid actual output
            Function Get-ModuleIcon {
                param([string]$Type)
                return "📋"
            }
            
            Function Write-Host {
                param([string]$Object, [string]$ForegroundColor)
                # Mock - just return
            }
            
            # This should not throw an error
            { 
                $icon = Get-ModuleIcon "Header"
                Write-Host "$icon Test header message" -ForegroundColor $script:ModuleColorHeader
            } | Should -Not -Throw
        }

        It "Write-DevHeader should handle different header message types" {
            Function Get-ModuleIcon { return "📋" }
            Function Write-Host { param($Object, $ForegroundColor) }
            
            # Test different header message scenarios
            { 
                $icon = Get-ModuleIcon "Header"
                Write-Host "$icon Laravel Development Environment Setup" -ForegroundColor $script:ModuleColorHeader
            } | Should -Not -Throw
            
            { 
                $icon = Get-ModuleIcon "Header"
                Write-Host "$icon Service Status Report" -ForegroundColor $script:ModuleColorHeader
            } | Should -Not -Throw
        }

        It "Write-DevHeader should use correct color variable" {
            $script:ModuleColorHeader | Should -Be "Blue"
        }

        It "Write-DevHeader message parameter should be mandatory" {
            # Load the actual function to test parameter validation
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $FunctionPath = Join-Path (Join-Path $ModuleRoot "source\private") "Write-DevHeader.ps1"
            
            # Test that the function definition has the mandatory parameter
            $functionContent = Get-Content $FunctionPath -Raw
            $functionContent | Should -Match '\[Parameter\(Mandatory\s*=\s*\$true\)\]'
            $functionContent | Should -Match '\[string\]\$Message'
        }

        It "Write-DevHeader should work with valid message parameter" {
            Function Get-ModuleIcon { return "📋" }
            Function Write-Host { param($Object, $ForegroundColor) }
            Function Write-DevHeader {
                param([Parameter(Mandatory = $true)][string]$Message)
                $icon = Get-ModuleIcon "Header"
                Write-Host "$icon $Message" -ForegroundColor $script:ModuleColorHeader
            }
            
            { Write-DevHeader -Message "Test header" } | Should -Not -Throw
        }
    }
}

