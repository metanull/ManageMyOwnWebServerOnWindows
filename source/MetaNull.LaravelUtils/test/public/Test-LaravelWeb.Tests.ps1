[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing public module function Test-LaravelWeb" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-LaravelWeb {
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
            
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                return $true  # Mock as if path exists
            }

            # Mock used module variables
            # N/A for this function
        }

        It "Test-LaravelWeb with running server should return true" {
            Mock Invoke-WebRequest {
                param([string]$Uri, [string]$Method, [int]$TimeoutSec, [string]$ErrorAction)
                return @{ StatusCode = 200 }  # Mock successful HTTP response
            }
            
            $Result = Test-LaravelWeb -Port 8000
            $Result | Should -Be $true
        }

        It "Test-LaravelWeb with default port should return true when server is running" {
            Mock Invoke-WebRequest {
                param([string]$Uri, [string]$Method, [int]$TimeoutSec, [string]$ErrorAction)
                return @{ StatusCode = 200 }  # Mock successful HTTP response
            }
            
            $Result = Test-LaravelWeb
            $Result | Should -Be $true
        }

        It "Test-LaravelWeb should return false when server is not responding" {
            Mock Test-DevPort {
                param([int]$Port)
                return $false  # Mock as if port is not available (server not running)
            }
            
            $Result = Test-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }

        It "Test-LaravelWeb should return false when HTTP request fails" {
            Mock Invoke-WebRequest {
                param([string]$Uri, [string]$Method, [int]$TimeoutSec, [string]$ErrorAction)
                throw "Connection failed"  # Mock HTTP request failure
            }
            
            $Result = Test-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }

        It "Test-LaravelWeb should return false when HTTP request times out" {
            Mock Invoke-WebRequest {
                param([string]$Uri, [string]$Method, [int]$TimeoutSec, [string]$ErrorAction)
                throw [System.Net.WebException]::new("The operation has timed out")  # Mock timeout
            }
            
            $Result = Test-LaravelWeb -Port 8000
            $Result | Should -Be $false
        }
    }
}
