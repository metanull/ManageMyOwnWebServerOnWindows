[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing private module function Wait-ForDevPort" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Wait-ForDevPort {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Test-DevPort {
                # N/A
            }
            Function Start-Sleep {
                # N/A
            }
            
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Default: port not available
            }
            
            Mock Start-Sleep {
                param([int]$Seconds)
                # Mock implementation - just return (no actual sleeping)
            }
        }

        It "Wait-ForDevPort should return true when port becomes available immediately" {
            Mock Test-DevPort {
                param([int]$Port)
                return $true  # Port is available immediately
            }
            
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 5
            $Result | Should -Be $true
            Should -Invoke Test-DevPort -Exactly 1 -Scope It
            Should -Invoke Start-Sleep -Exactly 0 -Scope It  # No sleep needed
        }

        It "Wait-ForDevPort should return true when port becomes available after delay" {
            Mock Test-DevPort {
                param([int]$Port)
                if ($script:WaitCallCount -eq $null) { $script:WaitCallCount = 0 }
                $script:WaitCallCount++
                # Return false for first 2 calls, then true
                return ($script:WaitCallCount -gt 2)
            }
            
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 5
            $Result | Should -Be $true
            Should -Invoke Test-DevPort -Exactly 3 -Scope It
            Should -Invoke Start-Sleep -Exactly 2 -Scope It  # Sleep called 2 times before success
        }

        It "Wait-ForDevPort should return false when timeout is reached" {
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Port never becomes available
            }
            
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 3 -IntervalSeconds 1
            $Result | Should -Be $false
            Should -Invoke Test-DevPort -Exactly 3 -Scope It  # Called 3 times (0, 1, 2 seconds)
            Should -Invoke Start-Sleep -Exactly 3 -Scope It
        }

        It "Wait-ForDevPort should use default timeout and interval" {
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Never available to test timeout
            }
            
            $Result = Wait-ForDevPort -Port 8000
            $Result | Should -Be $false
            # With default 10 second timeout and 1 second interval, should be called 10 times
            Should -Invoke Test-DevPort -Exactly 10 -Scope It
            Should -Invoke Start-Sleep -Exactly 10 -Scope It
        }

        It "Wait-ForDevPort should respect custom interval" {
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Never available
            }
            
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 4 -IntervalSeconds 2
            $Result | Should -Be $false
            # With 4 second timeout and 2 second interval: checks at 0, 2, 4 = 3 times
            Should -Invoke Test-DevPort -Exactly 2 -Scope It  # 0, 2 seconds (timeout at 4)
            Should -Invoke Start-Sleep -Exactly 2 -Scope It
        }

        It "Wait-ForDevPort should handle zero timeout" {
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 0
            $Result | Should -Be $false
            Should -Invoke Test-DevPort -Exactly 0 -Scope It  # No calls with zero timeout
            Should -Invoke Start-Sleep -Exactly 0 -Scope It
        }

        It "Wait-ForDevPort should return boolean type" {
            Mock Test-DevPort { return $true }
            
            $Result = Wait-ForDevPort -Port 8000 -TimeoutSeconds 1
            $Result | Should -BeOfType [bool]
        }
    }
}
