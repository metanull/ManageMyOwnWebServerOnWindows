[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function Test-DevelopmentServer" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-DevelopmentServer {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Test-WorkerWeb {
                # N/A
            }
            Function Test-WorkerVite {
                # N/A
            }
            Function Test-WorkerQueue {
                # N/A
            }
            Function Test-Path {
                # N/A
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Test-WorkerWeb {
                param([string]$Path, [int]$Port)
                return $true  # Mock successful test
            }
            
            Mock Test-WorkerVite {
                param([string]$Path, [int]$Port)
                return $true  # Mock successful test
            }
            
            Mock Test-WorkerQueue {
                param([string]$Path, [string]$Queue)
                return $true  # Mock successful test
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            

        }

        It "Test-DevelopmentServer should return all true when all services are running" {
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $true
            Should -Invoke Test-WorkerWeb -Exactly 1 -Scope It
            Should -Invoke Test-WorkerVite -Exactly 1 -Scope It
            Should -Invoke Test-WorkerQueue -Exactly 1 -Scope It
        }

        It "Test-DevelopmentServer should test with custom parameters" {
            $Result = Test-DevelopmentServer -WebPort 8080 -VitePort 3000 -Queue "emails"
            $Result.All | Should -Be $true
            Should -Invoke Test-WorkerWeb -Exactly 1 -Scope It
            Should -Invoke Test-WorkerVite -Exactly 1 -Scope It
            Should -Invoke Test-WorkerQueue -Exactly 1 -Scope It
        }

        It "Test-DevelopmentServer should handle web server not running" {
            Mock Test-WorkerWeb {
                param([string]$Path, [int]$Port)
                return $false  # Mock web server not running
            }
            
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $false
        }

        It "Test-DevelopmentServer should handle Vite server not running" {
            Mock Test-WorkerVite {
                param([string]$Path, [int]$Port)
                return $false  # Mock Vite server not running
            }
            
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $true
            $Result.All | Should -Be $false
        }

        It "Test-DevelopmentServer should handle queue worker not running" {
            Mock Test-WorkerQueue {
                param([string]$Path, [string]$Queue)
                return $false  # Mock queue worker not running
            }
            
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $true
            $Result.Vite | Should -Be $true
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
        }

        It "Test-DevelopmentServer should handle all services not running" {
            Mock Test-WorkerWeb { return $false }
            Mock Test-WorkerVite { return $false }
            Mock Test-WorkerQueue { return $false }
            
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
        }

        It "Test-DevelopmentServer should handle exceptions gracefully" {
            Mock Test-WorkerWeb {
                throw "System error"
            }
            
            $Result = Test-DevelopmentServer
            $Result.Web | Should -Be $false
            $Result.Vite | Should -Be $false
            $Result.Queue | Should -Be $false
            $Result.All | Should -Be $false
        }
    }
}
