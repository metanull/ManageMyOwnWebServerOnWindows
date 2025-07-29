[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Test file contains mock functions that do not require ShouldProcess')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
param()

Describe "Testing private module function Test-LaravelPath" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-LaravelPath {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Test-Path {
                # N/A
            }
            Function Write-Development {
                # N/A
            }

            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                # Simulate all paths as valid containers
                if ($PathType -eq 'Container') { return $true }
                # Simulate all files as present
                return $true
            }

            Mock Write-Development {
                param([string]$Message)
                # Mock implementation - just return
            }
        }

        It "Test-LaravelPath should return true for valid Laravel root" {
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $true
        }

        It "Test-LaravelPath should return false for missing directory" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($PathType -eq 'Container') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path 'C:\invalid\path'
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing artisan file" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'artisan') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing composer.json file" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'composer.json') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing vendor directory" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'vendor') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing package.json file" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'package.json') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing vite.config.js file" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'vite.config.js') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }

        It "Test-LaravelPath should return false for missing node_modules directory" {
            Mock Test-Path {
                param([string]$Path, [string]$PathType)
                if ($Path -match 'node_modules') { return $false }
                return $true
            }
            $Result = Test-LaravelPath -Path $env:TEMP
            $Result | Should -Be $false
        }
    }
}
