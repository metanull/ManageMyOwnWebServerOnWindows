[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Stop-LaravelVite" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Stop-LaravelVite {
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
            Function Write-DevStep {
                # N/A
            }
            Function Write-DevWarning {
                # N/A
            }
            Function Test-DevPort {
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
            
            Mock Write-DevStep {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Write-DevWarning {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Mock as if port is free
            }
            
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @(
                    [PSCustomObject]@{ OwningProcess = 5678 }
                )
            }
            
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Id = $Id
                    Name = "node"
                    ProcessName = "node"
                    CommandLine = "node node_modules/vite/bin/vite.js"
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

        It "Stop-LaravelVite should return true when no server is running" {
            Mock Test-DevPort { return $false }  # Port is FREE (no server running)
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $true
            Should -Invoke Write-DevInfo -Exactly 1 -Scope It
        }

        It "Stop-LaravelVite should stop Vite process successfully" {
            Mock Test-DevPort { 
                param([int]$Port)
                if ($script:ViteStopCallCount -eq $null) { $script:ViteStopCallCount = 0 }
                $script:ViteStopCallCount++
                if ($script:ViteStopCallCount -eq 1) { return $true }   # First call: port is busy
                return $false  # Second call: port is free after stopping
            }
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $true
            Should -Invoke Get-NetTCPConnection -Exactly 1 -Scope It
            Should -Invoke Get-Process -Exactly 1 -Scope It
        }

        It "Stop-LaravelVite should stop Vite process with Force" {
            Mock Test-DevPort { 
                param([int]$Port)
                if ($script:ViteStopCallCount2 -eq $null) { $script:ViteStopCallCount2 = 0 }
                $script:ViteStopCallCount2++
                if ($script:ViteStopCallCount2 -eq 1) { return $true }   # First call: port is busy
                return $false  # Second call: port is free after stopping
            }
            
            $Result = Stop-LaravelVite -Port 5173 -Force
            $Result | Should -Be $true
            Should -Invoke Read-Host -Exactly 0 -Scope It  # No confirmation with Force
        }

        It "Stop-LaravelVite should handle non-Vite process without Force" {
            Mock Test-DevPort { return $true }  # Port is busy
            Mock Get-Process {
                param([int]$Id, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Id = $Id
                    Name = "chrome"
                    ProcessName = "chrome"
                    CommandLine = "chrome.exe"
                    CloseMainWindow = { return $true }
                }
            }
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Times 2 -Exactly -Scope It
        }

        It "Stop-LaravelVite should handle no processes found on busy port" {
            Mock Test-DevPort { return $true }  # Port is busy
            Mock Get-NetTCPConnection {
                param([int]$LocalPort, [string]$ErrorAction)
                return @()  # No processes found
            }
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $false
            Should -Invoke Write-DevWarning -Exactly 1 -Scope It
        }

        It "Stop-LaravelVite should handle process stop failure" {
            Mock Test-DevPort { return $true }  # Port is busy and stays busy
            Mock Stop-Process {
                param([int]$Id, [switch]$Force)
                throw "Access denied"
            }
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $false
            Should -Invoke Write-DevError -Times 1 -Exactly -Scope It
        }

        It "Stop-LaravelVite should handle user declining to stop process" {
            Mock Test-DevPort { return $true }  # Port is busy and stays busy
            Mock Read-Host {
                param([string]$Prompt)
                return "N"  # User says no
            }
            
            $Result = Stop-LaravelVite -Port 5173
            $Result | Should -Be $false
        }
    }
}
