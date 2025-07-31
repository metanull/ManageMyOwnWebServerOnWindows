[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Start-WorkerVite" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Start-WorkerVite {
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
            Function Stop-Job {
                # N/A
            }
            Function Remove-Job {
                # N/A
            }
            Function Receive-Job {
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
                return [PSCustomObject]@{ 
                    Id = 456; 
                    State = "Running"
                    ChildJobs = @([PSCustomObject]@{ Error = @() })
                }
            }
            
            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return
            }
            
            Mock Stop-Job {
                param($Job, [string]$ErrorAction)
                # Mock implementation - just return
            }
            
            Mock Remove-Job {
                param($Job, [string]$ErrorAction)
                # Mock implementation - just return
            }
            
            Mock Receive-Job {
                param($Job, [string]$ErrorAction)
                return "Vite server started"
            }
            
        }

        It "Start-WorkerVite with free port should start successfully" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 456
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-WorkerVite with busy port should fail without Force" {
            Mock Test-DevPort { 
                param([int]$Port)
                return $true  # Port is busy
            }
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173
            $Result | Should -BeNullOrEmpty
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-WorkerVite with busy port and -Force should free it and start successfully" {
            Mock Test-DevPort { 
                param([int]$Port)
                if ($script:ViteCallCount -eq $null) { $script:ViteCallCount = 0 }
                $script:ViteCallCount++
                if ($script:ViteCallCount -eq 1) { return $true }   # First call: port is busy
                return $false  # Second call: port is free after stopping
            }
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173 -Force
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 456
            Should -Invoke Stop-DevProcessOnPort -Exactly 1 -Scope It
        }

        It "Start-WorkerVite should fail when port cannot be freed" {
            Mock Test-DevPort { return $true }  # Port remains busy after stop attempt
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173
            $Result | Should -Be $null
        }

        It "Start-WorkerVite should fail when server startup times out" {
            Mock Test-DevPort { return $false }  # Port is free
            Mock Wait-ForDevPort { return $false }  # Timeout
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173 -TimeoutSeconds 5
            $Result | Should -Be $null
            Should -Invoke Stop-Job -Exactly 1 -Scope It
            Should -Invoke Remove-Job -Exactly 1 -Scope It
        }

        It "Start-WorkerVite should start with custom ports" {
            Mock Test-DevPort { return $false }  # Port is free
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 3000 -LaravelPort 8080
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 456
        }

        It "Start-WorkerVite should handle failed job state" {
            Mock Test-DevPort { return $false }  # Port is free
            Mock Wait-ForDevPort { return $false }  # Timeout
            Mock Start-Job {
                return [PSCustomObject]@{ 
                    Id = 456; 
                    State = "Failed"
                    ChildJobs = @([PSCustomObject]@{ Error = @("Test error") })
                }
            }
            
            $Result = Start-WorkerVite -Path $env:TEMP -Port 5173
            $Result | Should -Be $null
        }
    }
}
