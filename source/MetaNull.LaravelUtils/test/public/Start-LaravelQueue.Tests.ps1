[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Start-LaravelQueue" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Start-LaravelQueue {
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
            Function Stop-LaravelQueue {
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
            
            Mock Stop-LaravelQueue {
                param([string]$Path, [string]$Queue, [switch]$Force)
                # Mock implementation - just return
            }
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            
            Mock Start-Job {
                return [PSCustomObject]@{ 
                    Id = 789; 
                    State = "Running"
                }
            }
            
            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return
            }
            
            Mock Remove-Job {
                param($Job, [string]$ErrorAction)
                # Mock implementation - just return
            }
            
            Mock Receive-Job {
                param($Job, [string]$ErrorAction)
                return "Queue worker started"
            }
            
        }

        It "Start-LaravelQueue should start successfully with default settings" {
            $Result = Start-LaravelQueue
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 789
            $Result.State | Should -Be "Running"
            Should -Invoke Write-DevSuccess -Exactly 1 -Scope It
        }

        It "Start-LaravelQueue should start with custom queue name" {
            $Result = Start-LaravelQueue -Queue "emails"
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 789
            Should -Invoke Write-DevStep -Exactly 1 -Scope It
        }

        It "Start-LaravelQueue should start with Force and stop existing workers" {
            $Result = Start-LaravelQueue -Queue "default" -Force
            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke Stop-LaravelQueue -Exactly 1 -Scope It
            Should -Invoke Write-DevInfo -Exactly 2 -Scope It
        }

        It "Start-LaravelQueue should start with custom parameters" {
            $Result = Start-LaravelQueue -Queue "notifications" -MaxJobs 500 -MaxTime 1800 -Sleep 5 -Timeout 120
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 789
        }

        It "Start-LaravelQueue should start with connection name" {
            $Result = Start-LaravelQueue -ConnectionName "redis" -Queue "high-priority"
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 789
        }

        It "Start-LaravelQueue should fail when job fails to start" {
            Mock Start-Job {
                return [PSCustomObject]@{ 
                    Id = 789; 
                    State = "Failed"
                }
            }
            
            $Result = Start-LaravelQueue
            $Result | Should -Be $null
            Should -Invoke Write-DevError -Times 2 -Exactly -Scope It
            Should -Invoke Remove-Job -Exactly 1 -Scope It
        }

        It "Start-LaravelQueue should handle job that stops immediately" {
            Mock Start-Job {
                return [PSCustomObject]@{ 
                    Id = 789; 
                    State = "Completed"
                }
            }
            
            $Result = Start-LaravelQueue
            $Result | Should -Be $null
            Should -Invoke Write-DevError -Times 2 -Exactly -Scope It
        }
    }
}
