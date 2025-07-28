[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing public module function Start-LaravelWeb" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Start-LaravelWeb {
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

        It "Start-LaravelWeb with free port should start successfully" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 123
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-LaravelWeb with busy port and Force should start successfully" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Be 123
        }

        It "Start-LaravelWeb with Force should call Stop-DevProcessOnPort on busy port" {
            # Mock Test-DevPort to return true first (busy), then false (free) after Stop-DevProcessOnPort is called
            $script:portCheckCount = 0
            Mock Test-DevPort { 
                $script:portCheckCount++
                if ($script:portCheckCount -eq 1) { return $true }  # First check: Port is BUSY
                return $false  # Subsequent checks: Port is FREE after Stop-DevProcessOnPort
            }
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke Stop-DevProcessOnPort -Exactly 1 -Scope It
        }

        It "Start-LaravelWeb with Force should not call Stop-DevProcessOnPort on free port" {
            Mock Test-DevPort { return $false }  # Port is FREE (not in use)
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000 -Force
            $Result | Should -Not -BeNullOrEmpty
            Should -Invoke Stop-DevProcessOnPort -Exactly 0 -Scope It
        }

        It "Start-LaravelWeb with busy port without Force should fail" {
            Mock Test-DevPort { return $true }  # Port is BUSY (in use) and stays busy
            Mock Write-DevError { param([string]$Message) }  # Override to capture error
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000
            $Result | Should -Be $null
            # Verify that Stop-DevProcessOnPort was called as part of automatic port freeing
            Should -Invoke Stop-DevProcessOnPort -Exactly 1 -Scope It
        }

        It "Start-LaravelWeb with server startup timeout should fail" {
            Mock Wait-ForDevPort { return $false }  # Timeout
            Mock Write-DevError { param([string]$Message) }  # Override to capture error
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000 -TimeoutSeconds 5
            $Result | Should -Be $null
        }

        It "Start-LaravelWeb with SkipChecks should start without port validation" {
            Mock Test-DevPort { return $true }  # This should be ignored with SkipChecks
            $Result = Start-LaravelWeb -Path $env:TEMP -Port 8000 -SkipChecks
            $Result | Should -Not -BeNullOrEmpty
        }
    }
}
