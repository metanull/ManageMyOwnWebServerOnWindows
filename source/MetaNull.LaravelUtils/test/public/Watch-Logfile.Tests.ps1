[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing private module function Watch-Logfile" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Watch-Logfile {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Test-LaravelPath {}
            Function Get-LogfilePath {}
            Function Test-Path {}
            Function Write-Warning {}
            Function Clear-Content {}
            Function Get-Content {}

            Mock Test-LaravelPath {
                return $true  # Mock as if path is valid
            }
            Mock Clear-Content {
                param([string]$Path, [switch]$ErrorAction)
                # Mock implementation - just return
            }
            Mock Get-LogfilePath {
                param([string]$Path)
                # Mock implementation - return a fixed log file path
                return 'C:\Path\To\Laravel\storage\logs\laravel.log'
            }
            Mock Get-Content {
                param([string]$Path)
                # Mock implementation - return a fixed content
                return "Mocked content"
            }
            Mock Write-Warning {
                param([string]$Message)
                # Mock implementation - just return
            }
        }

        It "Returns when log file does not exist" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $false  # Mock as if path does not exist
            }
            Watch-Logfile -Path 'C:\Path\To\Laravel'
            Should -Not -Invoke Clear-Content -Scope It
            Should -Not -Invoke Get-Content -Scope It
            Should -Invoke Write-Warning -Exactly 1 -Scope It
        }

        It "Reads the log file it exists" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            Watch-Logfile -Path 'C:\Path\To\Laravel'
            Should -Invoke Get-Content -Exactly 1 -Scope It
            Should -Not -Invoke Write-Warning -Scope It
            Should -Not -Invoke Clear-Content -Scope It
        }

        It "Clears the log file if -Clear is specified" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            Watch-Logfile -Path 'C:\Path\To\Laravel' -Clear
            Should -Invoke Clear-Content -Exactly 1 -Scope It
        }

    }
}
