[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function Test-LaravelQueue" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-LaravelQueue {
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
            Function Test-Path {
                # N/A
            }
            Function Get-WmiObject {
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
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }
            
            Mock Get-WmiObject {
                param([string]$Class)
                return @(
                    [PSCustomObject]@{
                        Name = "php.exe"
                        CommandLine = "php artisan queue:work --queue=default"
                        ProcessId = 1234
                        CreationDate = "20250128000000.000000+000"
                    }
                )
            }
        }

        It "Test-LaravelQueue should return true when queue workers are running" {
            $Result = Test-LaravelQueue -Path $env:TEMP
            $Result | Should -Be $true
            Should -Invoke Write-DevSuccess -Exactly 1 -Scope It
            Should -Invoke Write-DevInfo -Exactly 2 -Scope It  # Initial message + process info
        }

        It "Test-LaravelQueue should return true when specific queue worker is running" {
            Mock Get-WmiObject {
                param([string]$Class)
                return @(
                    [PSCustomObject]@{
                        Name = "php.exe"
                        CommandLine = "php artisan queue:work --queue=emails"
                        ProcessId = 1234
                        CreationDate = "20250128000000.000000+000"
                    }
                )
            }
            
            $Result = Test-LaravelQueue -Path $env:TEMP -Queue "emails"
            $Result | Should -Be $true
            Should -Invoke Write-DevSuccess -Exactly 1 -Scope It
        }

        It "Test-LaravelQueue should return false when no queue workers are running" {
            Mock Get-WmiObject {
                param([string]$Class)
                return @()  # No processes found
            }
            
            $Result = Test-LaravelQueue -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevInfo -Exactly 2 -Scope It  # Initial message + no processes found
        }

        It "Test-LaravelQueue should return false when specific queue worker is not running" {
            Mock Get-WmiObject {
                param([string]$Class)
                return @(
                    [PSCustomObject]@{
                        Name = "php.exe"
                        CommandLine = "php artisan queue:work --queue=default"
                        ProcessId = 1234
                        CreationDate = "20250128000000.000000+000"
                    }
                )
            }
            
            $Result = Test-LaravelQueue -Path $env:TEMP -Queue "emails"
            $Result | Should -Be $false
            Should -Invoke Write-DevInfo -Exactly 2 -Scope It
        }

        It "Test-LaravelQueue should handle multiple queue workers" {
            Mock Get-WmiObject {
                param([string]$Class)
                return @(
                    [PSCustomObject]@{
                        Name = "php.exe"
                        CommandLine = "php artisan queue:work --queue=default"
                        ProcessId = 1234
                        CreationDate = "20250128000000.000000+000"
                    },
                    [PSCustomObject]@{
                        Name = "php.exe"
                        CommandLine = "php artisan queue:work --queue=emails"
                        ProcessId = 5678
                        CreationDate = "20250128000000.000000+000"
                    }
                )
            }
            
            $Result = Test-LaravelQueue -Path $env:TEMP
            $Result | Should -Be $true
            Should -Invoke Write-DevInfo -Exactly 3 -Scope It  # Initial + 2 process info
        }

        It "Test-LaravelQueue should handle WMI query errors" {
            Mock Get-WmiObject {
                param([string]$Class)
                throw "WMI query failed"
            }
            
            $Result = Test-LaravelQueue -Path $env:TEMP
            $Result | Should -Be $false
            Should -Invoke Write-DevError -Exactly 1 -Scope It
        }
    }
}
