[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Stop-DevelopmentServer" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-DevelopmentServer {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Stop-WorkerWeb {
                # N/A
            }
            Function Stop-WorkerVite {
                # N/A
            }
            Function Stop-WorkerQueue {
                # N/A
            }
            Function Test-Path {
                # N/A
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Stop-WorkerWeb {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Stop-WorkerVite {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Stop-WorkerQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
        }

        It "Stop-DevelopmentServer should stop all services successfully with defaults" {
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $true
            Should -Invoke Stop-WorkerWeb -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerVite -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerQueue -Exactly 1 -Scope It
        }

        It "Stop-DevelopmentServer should stop with custom parameters" {
            $Result = Stop-DevelopmentServer -WebPort 8080 -VitePort 3000 -Queue "emails"
            $Result | Should -Be $true
            Should -Invoke Stop-WorkerWeb -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerVite -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerQueue -Exactly 1 -Scope It
        }

        It "Stop-DevelopmentServer should handle Force parameter" {
            $Result = Stop-DevelopmentServer -Force
            $Result | Should -Be $true
            Should -Invoke Stop-WorkerWeb -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerVite -Exactly 1 -Scope It
            Should -Invoke Stop-WorkerQueue -Exactly 1 -Scope It
        }

        It "Stop-DevelopmentServer should handle web server stop failure" {
            Mock Stop-WorkerWeb {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $false
        }

        It "Stop-DevelopmentServer should handle Vite server stop failure" {
            Mock Stop-WorkerVite {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $false
        }

        It "Stop-DevelopmentServer should handle queue worker stop failure" {
            Mock Stop-WorkerQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $false
        }

        It "Stop-DevelopmentServer should handle multiple service failures" {
            Mock Stop-WorkerWeb { return $false }
            Mock Stop-WorkerVite { return $false }
            Mock Stop-WorkerQueue { return $false }
            
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $false
        }

        It "Stop-DevelopmentServer should handle exceptions gracefully" {
            Mock Stop-WorkerWeb {
                throw "System error"
            }
            
            $Result = Stop-DevelopmentServer
            $Result | Should -Be $false
        }
    }
}
