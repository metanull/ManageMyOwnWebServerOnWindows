[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Test file contains mock functions with intentionally unused parameters')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '', Justification = 'Test file needs to mock built-in cmdlets for isolated testing')]
param()

Describe "Testing private module function Test-DevCommand" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Test-DevCommand {
                . $FunctionPath @args | Write-Output
            }

            # Mock other module and system functions
            Function Get-Command {
                # N/A
            }
            
            Mock Get-Command {
                param([string]$Name, [string]$ErrorAction)
                # Default: return a mock command object (command exists)
                return [PSCustomObject]@{
                    Name = $Name
                    CommandType = "Application"
                    Source = "C:\mock\path\$Name.exe"
                }
            }
        }

        It "Test-DevCommand should return true when command exists" {
            $Result = Test-DevCommand -Command "php"
            $Result | Should -Be $true
            Should -Invoke Get-Command -Exactly 1 -Scope It
        }

        It "Test-DevCommand should return false when command does not exist" {
            Mock Get-Command {
                param([string]$Name, [string]$ErrorAction)
                throw "Command not found"
            }
            
            $Result = Test-DevCommand -Command "nonexistent-command"
            $Result | Should -Be $false
            Should -Invoke Get-Command -Exactly 1 -Scope It
        }

        It "Test-DevCommand should return boolean type" {
            $Result = Test-DevCommand -Command "test"
            $Result | Should -BeOfType [bool]
        }

        It "Test-DevCommand should test common development commands" {
            # Test various commands that exist
            $PhpResult = Test-DevCommand -Command "php"
            $NodeResult = Test-DevCommand -Command "node"
            $GitResult = Test-DevCommand -Command "git"
            
            $PhpResult | Should -BeOfType [bool]
            $NodeResult | Should -BeOfType [bool]
            $GitResult | Should -BeOfType [bool]
        }

        It "Test-DevCommand should handle whitespace command name" {
            Mock Get-Command {
                param([string]$Name, [string]$ErrorAction)
                throw "Command name is whitespace"
            }
            
            $Result = Test-DevCommand -Command " "
            $Result | Should -Be $false
        }

        It "Test-DevCommand should handle PowerShell cmdlets" {
            Mock Get-Command {
                param([string]$Name, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Name = $Name
                    CommandType = "Cmdlet"
                    ModuleName = "Microsoft.PowerShell.Core"
                }
            }
            
            $Result = Test-DevCommand -Command "Get-Process"
            $Result | Should -Be $true
        }

        It "Test-DevCommand should handle aliases" {
            Mock Get-Command {
                param([string]$Name, [string]$ErrorAction)
                return [PSCustomObject]@{
                    Name = $Name
                    CommandType = "Alias"
                    ReferencedCommand = "Get-ChildItem"
                }
            }
            
            $Result = Test-DevCommand -Command "ls"
            $Result | Should -Be $true
        }
    }
}
