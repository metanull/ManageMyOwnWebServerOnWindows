[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Start-Laravel" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Start-Laravel {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Start-LaravelWeb {
                # N/A
            }
            Function Start-LaravelVite {
                # N/A
            }
            Function Start-LaravelQueue {
                # N/A
            }
            Function Test-Path {
                # N/A
            }

            Function Test-LaravelPath {
                # N/A
            }

            Mock Test-LaravelPath {
                param([string]$Path)
                return $true  # Always validate path as correct for tests
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Start-LaravelWeb {
                param([string]$Path, [int]$Port, [int]$TimeoutSeconds, [switch]$Force)
                return [PSCustomObject]@{ Id = 100; State = "Running" }  # Mock successful start
            }
            
            Mock Start-LaravelVite {
                param([string]$Path, [int]$Port, [int]$LaravelPort, [int]$TimeoutSeconds, [switch]$Force)
                return [PSCustomObject]@{ Id = 200; State = "Running" }  # Mock successful start
            }
            
            Mock Start-LaravelQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return [PSCustomObject]@{ Id = 300; State = "Running" }  # Mock successful start
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
        }

        It "Start-Laravel should start all services successfully with defaults" {
            $Result = Start-Laravel -Path $env:TEMP
            $Result | Should -Be $true
            Should -Invoke Start-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Start-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Start-LaravelQueue -Exactly 1 -Scope It
        }

        It "Start-Laravel should start with custom parameters" {
            $Result = Start-Laravel -Path $env:TEMP -WebPort 8080 -VitePort 3000 -Queue "emails" -TimeoutSeconds 60
            $Result | Should -Be $true
            Should -Invoke Start-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Start-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Start-LaravelQueue -Exactly 1 -Scope It
        }

        It "Start-Laravel should handle Force parameter" {
            $Result = Start-Laravel -Path $env:TEMP -Force
            $Result | Should -Be $true
            Should -Invoke Start-LaravelWeb -Exactly 1 -Scope It
            Should -Invoke Start-LaravelVite -Exactly 1 -Scope It
            Should -Invoke Start-LaravelQueue -Exactly 1 -Scope It
        }

        It "Start-Laravel should fail when web server fails to start" {
            Mock Start-LaravelWeb {
                param([string]$Path, [int]$Port, [int]$TimeoutSeconds, [switch]$Force)
                return $null  # Mock failure
            }
            
            $Result = Start-Laravel -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Start-Laravel should fail when Vite server fails to start" {
            Mock Start-LaravelVite {
                param([string]$Path, [int]$Port, [int]$LaravelPort, [int]$TimeoutSeconds, [switch]$Force)
                return $null  # Mock failure
            }
            
            $Result = Start-Laravel -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Start-Laravel should fail when queue worker fails to start" {
            Mock Start-LaravelQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                return $null  # Mock failure
            }
            
            $Result = Start-Laravel -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Start-Laravel should handle exceptions gracefully" {
            Mock Start-LaravelWeb {
                throw "System error"
            }
            
            $Result = Start-Laravel -Path $env:TEMP
            $Result | Should -Be $false
        }
    }
}
