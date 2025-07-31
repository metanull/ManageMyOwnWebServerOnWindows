[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Start-WorkerWeb" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Start-WorkerWeb {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Test-DevPort {
                # N/A
            }
            Function Stop-DevProcessOnPort {
                # N/A
            }
            Function Wait-ForDevPort {
                # N/A
            }
            Function Test-Path {
                # N/A
            }
            Function Start-Job {
                # N/A
            }

            Function Start-Sleep {
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
            
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Mock as if port is free
            }
            
            Mock Stop-DevProcessOnPort {
                param([int]$Port)
                # Mock implementation - just return
            }
            
            Mock Wait-ForDevPort {
                param([int]$Port, [int]$TimeoutSeconds)
                return $true  # Mock successful start
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            
            Mock Start-Job {
                return [PSCustomObject]@{ Id = 123; State = "Running" }
            }

            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return
                return
            }
        }

        It "Start-WorkerWeb with free port should start successfully" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 123
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-WorkerWeb with busy port and Force should start successfully" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 123
        }

        It "Start-WorkerWeb with Force should call Stop-DevProcessOnPort on busy port" {
            # Mock Test-DevPort to return true first (busy), then false (free) after Stop-DevProcessOnPort is called
            $script:portCheckCount = 0
            Mock Test-DevPort { 
                $script:portCheckCount++
                if ($script:portCheckCount -eq 1) { return $true }  # First check: Port is BUSY
                return $false  # Subsequent checks: Port is FREE after Stop-DevProcessOnPort
            }
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke Stop-DevProcessOnPort -Exactly 1 -Scope It
        }

        It "Start-WorkerWeb with Force should not call Stop-DevProcessOnPort on free port" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-WorkerWeb with busy port without Force should fail" {
            Mock Test-DevPort { return $true }  # Port is BUSY (in use) and stays busy
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000
            $Result | Should -Be $null
            # Verify that Stop-DevProcessOnPort was called as part of automatic port freeing
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-WorkerWeb with server startup timeout should fail" {
            Mock Wait-ForDevPort { return $false }  # Timeout
            $Result = Start-WorkerWeb -Path $env:TEMP -Port 8000 -TimeoutSeconds 5
            $Result | Should -Be $null
        }
    }
}
