[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Stop-LaravelQueue" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-LaravelQueue {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Test-Path {
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
            Function Read-Host {
                # N/A
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            
            Mock Stop-Process {
                param([int]$Id, [switch]$Force)
                # Mock implementation - just return
            }
            
            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return
            }
            
            Mock Read-Host {
                param([string]$Prompt)
                return "Y"  # Default to yes for confirmation
            }
        }

        It "Stop-LaravelQueue should return true when no queue workers are running" {
            Mock Get-Process {
                return @()  # No processes found
            }
            
            $Result = Stop-LaravelQueue
            $Result | Should -Be $true
        }

        It "Stop-LaravelQueue should handle Get-Process error gracefully" {
            Mock Get-Process {
                throw "System error"
            }
            
            $Result = Stop-LaravelQueue
            $Result | Should -Be $false
        }

        It "Stop-LaravelQueue should handle empty process list" {
            Mock Get-Process {
                # Return processes but they won't match the filter due to missing CommandLine
                return @(
                    [PSCustomObject]@{
                        Id = 9999
                        ProcessName = "notepad"
                    }
                )
            }
            
            $Result = Stop-LaravelQueue
            $Result | Should -Be $true
        }

        It "Stop-LaravelQueue should handle Force parameter" {
            Mock Get-Process {
                return @()  # No processes found
            }
            
            $Result = Stop-LaravelQueue -Force
            $Result | Should -Be $true
            Should -Invoke Read-Host -Exactly 0 -Scope It  # No confirmation with Force
        }

        It "Stop-LaravelQueue should handle Queue parameter" {
            Mock Get-Process {
                return @()  # No processes found
            }
            
            $Result = Stop-LaravelQueue -Queue "emails"
            $Result | Should -Be $true
        }
    }
}
