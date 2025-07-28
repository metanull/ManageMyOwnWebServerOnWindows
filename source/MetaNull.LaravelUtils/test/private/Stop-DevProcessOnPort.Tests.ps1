[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing private module function Stop-DevProcessOnPort" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-DevProcessOnPort {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-DevWarning {
                # N/A
            }
            Function Get-NetTCPConnection {
                # N/A
            }
            Function Get-Process {
                # N/A
            }
            Function Stop-Process {
                # N/A
            }
            Function Start-Sleep {
                # N/A
            }
            
            Mock Write-DevWarning {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @(
                    [PSCustomObject]@{ OwningProcess = 1234 },
                    [PSCustomObject]@{ OwningProcess = 5678 }
                )
            }
            
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Id = $Id
                    Name = "test-process"
                }
            }
            
            Mock Stop-Process {
                param([int]$Id, [switch]$Force)
                # Mock implementation - just return
            }
            
            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return
            }
        }

        It "Stop-DevProcessOnPort should stop processes on specified port" {
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Get-NetTCPConnection -Exactly 1 -Scope It
            Should -Invoke Get-Process -Exactly 2 -Scope It  # Two processes in our mock
            Should -Invoke Stop-Process -Exactly 2 -Scope It
            Should -Invoke Write-DevWarning -Exactly 2 -Scope It
        }

        It "Stop-DevProcessOnPort should handle no processes on port" {
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @()  # No processes
            }
            
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Get-NetTCPConnection -Exactly 1 -Scope It
            Should -Invoke Get-Process -Exactly 0 -Scope It
            Should -Invoke Stop-Process -Exactly 0 -Scope It
        }

        It "Stop-DevProcessOnPort should handle process not found" {
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return $null  # Process not found
            }
            
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Get-NetTCPConnection -Exactly 1 -Scope It
            Should -Invoke Get-Process -Exactly 2 -Scope It
            Should -Invoke Stop-Process -Exactly 0 -Scope It  # No processes to stop
        }

        It "Stop-DevProcessOnPort should handle zero process ID" {
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @(
                    [PSCustomObject]@{ OwningProcess = 0 },  # Zero PID
                    [PSCustomObject]@{ OwningProcess = 1234 }
                )
            }
            
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Get-Process -Exactly 1 -Scope It  # Only called for non-zero PID
            Should -Invoke Stop-Process -Exactly 1 -Scope It
        }

        It "Stop-DevProcessOnPort should handle exceptions gracefully" {
            Mock Get-NetTCPConnection {
                throw "Access denied"
            }
            
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It  # Error warning
        }

        It "Stop-DevProcessOnPort should handle Stop-Process exceptions" {
            Mock Stop-Process {
                param([int]$Id, [switch]$Force)
                throw "Access denied"
            }
            
            Stop-DevProcessOnPort -Port 8000
            
            Should -Invoke Write-DevWarning -Exactly 2 -Scope It  # 2 process warnings (Stop-Process failure is silent)
        }
    }
}
