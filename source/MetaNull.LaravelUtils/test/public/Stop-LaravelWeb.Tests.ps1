[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Stop-LaravelWeb" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-LaravelWeb {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Test-DevPort {
                # N/A
            }
            Function Test-Path {
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
            Function Read-Host {
                # N/A
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Mock as if port is free
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @(
                    [PSCustomObject]@{ OwningProcess = 1234 }
                )
            }
            
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Id = $Id
                    Name = "php"
                    ProcessName = "php"
                    CommandLine = "php artisan serve --port=8000"
                    CloseMainWindow = { return $true }
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
            
            Mock Read-Host {
                param([string]$Prompt)
                return "Y"  # Default to yes for confirmation
            }
        }

        It "Stop-LaravelWeb should return true when no server is running" {
            Mock Test-DevPort { return $false }  # Port is FREE (no server running)
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $true
        }

        It "Stop-LaravelWeb should stop Laravel process successfully" {
            Mock Test-DevPort { 
                param([int]$Port)
                if ($script:CallCount -eq $null) { $script:CallCount = 0 }
                $script:CallCount++
                if ($script:CallCount -eq 1) { return $true }   # First call: port is busy
                return $false  # Second call: port is free after stopping
            }
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $true
            Should -Invoke Get-NetTCPConnection -Exactly 1 -Scope It
            Should -Invoke Get-Process -Exactly 1 -Scope It
        }

        It "Stop-LaravelWeb should stop Laravel process with Force" {
            Mock Test-DevPort { 
                param([int]$Port)
                if ($script:CallCount2 -eq $null) { $script:CallCount2 = 0 }
                $script:CallCount2++
                if ($script:CallCount2 -eq 1) { return $true }   # First call: port is busy
                return $false  # Second call: port is free after stopping
            }
            
            $Result = Stop-LaravelWeb -Port 8000 -Force
            $Result | Should -Be $true
            Should -Invoke Read-Host -Exactly 0 -Scope It  # No confirmation with Force
        }

        It "Stop-LaravelWeb should handle non-Laravel process without Force" {
            Mock Test-DevPort { return $true }  # Port is busy
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Id = $Id
                    Name = "notepad"
                    ProcessName = "notepad"
                    CommandLine = "notepad.exe"
                    CloseMainWindow = { return $true }
                }
            }
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }

        It "Stop-LaravelWeb should handle no processes found on busy port" {
            Mock Test-DevPort { return $true }  # Port is busy
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @()  # No processes found
            }
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }

        It "Stop-LaravelWeb should handle process stop failure" {
            Mock Test-DevPort { return $true }  # Port is busy and stays busy
            Mock Stop-Process {
                param([int]$Id, [switch]$Force)
                throw "Access denied"
            }
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }

        It "Stop-LaravelWeb should handle user declining to stop process" {
            Mock Test-DevPort { return $true }  # Port is busy and stays busy
            Mock Read-Host {
                param([string]$Prompt)
                return "N"  # User says no
            }
            
            $Result = Stop-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }
    }
}
