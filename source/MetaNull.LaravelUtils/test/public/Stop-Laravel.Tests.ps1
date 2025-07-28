[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Stop-Laravel" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-Laravel {
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
            Function Stop-LaravelWeb {
                # N/A
            }
            Function Stop-LaravelVite {
                # N/A
            }
            Function Stop-LaravelQueue {
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
            
            Mock Stop-LaravelWeb {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Stop-LaravelVite {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Stop-LaravelQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return $true  # Mock successful stop
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
        }

        It "Stop-Laravel should stop all services successfully with defaults" {
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $true
            Should -Invoke Stop-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelQueue -Exactly 1 -Scope It
            Should -Invoke Write-DevSuccess -Exactly 1 -Scope It
        }

        It "Stop-Laravel should stop with custom parameters" {
            $Result = Stop-Laravel -Path $env:TEMP -WebPort 8080 -VitePort 3000 -Queue "emails"
            $Result | Should -Be $true
            Should -Invoke Stop-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelQueue -Exactly 1 -Scope It
        }

        It "Stop-Laravel should handle Force parameter" {
            $Result = Stop-Laravel -Path $env:TEMP -Force
            $Result | Should -Be $true
            Should -Invoke Stop-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Stop-LaravelQueue -Exactly 1 -Scope It
        }

        It "Stop-Laravel should handle web server stop failure" {
            Mock Stop-LaravelWeb {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Times 2 -Exactly -Scope It  # One for web failure + one for overall
        }

        It "Stop-Laravel should handle Vite server stop failure" {
            Mock Stop-LaravelVite {
                param([string]$Path, [int]$Port, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Times 2 -Exactly -Scope It  # One for vite failure + one for overall
        }

        It "Stop-Laravel should handle queue worker stop failure" {
            Mock Stop-LaravelQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return $false  # Mock failure
            }
            
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Times 2 -Exactly -Scope It  # One for queue failure + one for overall
        }

        It "Stop-Laravel should handle multiple service failures" {
            Mock Stop-LaravelWeb { return $false }
            Mock Stop-LaravelVite { return $false }
            Mock Stop-LaravelQueue { return $false }
            
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Times 4 -Exactly -Scope It  # Three for service failures + one for overall
        }

        It "Stop-Laravel should handle exceptions gracefully" {
            Mock Stop-LaravelWeb {
                throw "System error"
            }
            
            $Result = Stop-Laravel -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevError -Times 1 -Exactly -Scope It
        }
    }
}
