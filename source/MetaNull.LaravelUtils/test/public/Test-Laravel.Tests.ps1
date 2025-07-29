[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function Test-Laravel" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-Laravel {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-DevInfo {
                # N/A
            }
            Function Write-DevError {
                # N/A
            }
            Function Write-DevSuccess {
                # N/A
            }
            Function Write-DevHeader {
                # N/A
            }
            Function Write-DevWarning {
                # N/A
            }
            Function Test-LaravelWeb {
                # N/A
            }
            Function Test-LaravelVite {
                # N/A
            }
            Function Test-LaravelQueue {
                # N/A
            }
            Function Test-Path {
                # N/A
            }
            
            Mock Write-DevInfo {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Write-DevError {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Write-DevSuccess {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Write-DevHeader {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Write-DevWarning {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Test-LaravelWeb {
                param([string]$Path, [int]$Port)
                return $true  # Mock successful test
            }
            
            Mock Test-LaravelVite {
                param([string]$Path, [int]$Port)
                return $true  # Mock successful test
            }
            
            Mock Test-LaravelQueue {
                param([string]$Path, [string]$Queue)
                return $true  # Mock successful test
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            

        }

        It "Test-Laravel should return all true when all services are running" {
            $Result = Test-Laravel
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $true
            Should -Invoke Test-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Test-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Test-LaravelQueue -Exactly 1 -Scope It
            Should -Invoke Write-DevSuccess -Exactly 1 -Scope It
        }

        It "Test-Laravel should test with custom parameters" {
            $Result = Test-Laravel -WebPort 8080 -VitePort 3000 -Queue "emails"
            $Result.All | Should -Be $true
            Should -Invoke Test-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Test-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Test-LaravelQueue -Exactly 1 -Scope It
        }

        It "Test-Laravel should handle web server not running" {
            Mock Test-LaravelWeb {
                param([string]$Path, [int]$Port)
                return $false  # Mock web server not running
            }
            
            $Result = Test-Laravel
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $false
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It
        }

        It "Test-Laravel should handle Vite server not running" {
            Mock Test-LaravelVite {
                param([string]$Path, [int]$Port)
                return $false  # Mock Vite server not running
            }
            
            $Result = Test-Laravel
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $false
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It
        }

        It "Test-Laravel should handle queue worker not running" {
            Mock Test-LaravelQueue {
                param([string]$Path, [string]$Queue)
                return $false  # Mock queue worker not running
            }
            
            $Result = Test-Laravel
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It
        }

        It "Test-Laravel should handle all services not running" {
            Mock Test-LaravelWeb { return $false }
            Mock Test-LaravelVite { return $false }
            Mock Test-LaravelQueue { return $false }
            
            $Result = Test-Laravel
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It
        }

        It "Test-Laravel should handle exceptions gracefully" {
            Mock Test-LaravelWeb {
                throw "System error"
            }
            
            $Result = Test-Laravel
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
            Should -Invoke Write-DevError -Times 1 -Exactly -Scope It
        }
    }
}
