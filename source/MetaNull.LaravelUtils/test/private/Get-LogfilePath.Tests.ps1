[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing private module function Get-LogfilePath" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Get-LogfilePath {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Test-LaravelPath {
                # N/A
            }
            Function Join-Path {
                # N/A
            }

            Mock Test-LaravelPath {
                return $true
            }
            Mock Join-Path {
                param([string]$Path, [string]$ChildPath)
                return "$Path\$ChildPath"  # Mock implementation
            }
            $script:ModuleLaravelLogFile = 'Path\To\Logfile.log'
        }

        It "Validates param with Test-LaravelPath" {

            $Result = Get-LogfilePath -Path 'Mocked:'
            $Result | Should -Not -BeNullOrEmpty
            $Result | Should -Be 'Mocked:\Path\To\Logfile.log'
            Should -Invoke Join-Path -Exactly 1 -Scope It
            Should -Invoke Test-LaravelPath -Exactly 1 -Scope It
        }
    }
}
