[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function Test-WorkerVite" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-WorkerVite {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Write-Development {
                # N/A
            }
            Function Test-DevPort {
                # N/A
            }
            Function Invoke-WebRequest {
                # N/A
            }
            
            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
            
            Mock Test-DevPort {
                param([int]$Port)
                return $true  # Mock as if port is available (server running)
            }

            }

        It "Test-WorkerVite with running server should return true" {
            Mock Invoke-WebRequest { 
                return [PSCustomObject]@{ StatusCode = 200; Content = "vite" }
            }
            $Result = Test-WorkerVite -Port 5173
            $Result | Should -Be $true
        }

        It "Test-WorkerVite with non-running server should return false" {
            Mock Test-DevPort { return $false }  # Port not listening
            $Result = Test-WorkerVite -Port 5173
            $Result | Should -Be $false
        }

        It "Test-WorkerVite with HTTP response should return true regardless of content" {
            Mock Invoke-WebRequest { 
                return [PSCustomObject]@{ StatusCode = 200; Content = "not vite" }
            }
            $Result = Test-WorkerVite -Port 5173
            $Result | Should -Be $true  # Function doesn't check content, just HTTP response
        }

        It "Test-WorkerVite with web request timeout should return false" {
            Mock Invoke-WebRequest { 
                throw [System.Net.WebException]::new("The operation has timed out")
            }
            $Result = Test-WorkerVite -Port 5173
            $Result | Should -Be $false
        }

        It "Test-WorkerVite with default port should work" {
            Mock Invoke-WebRequest { 
                return [PSCustomObject]@{ StatusCode = 200; Content = "vite" }
            }
            $Result = Test-WorkerVite
            $Result | Should -Be $true
        }
    }
}
