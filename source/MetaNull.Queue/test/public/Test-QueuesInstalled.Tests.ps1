Describe "Test-QueuesInstalled" -Tag "UnitTest" {

    Context "When not Installed" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }

            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
        }

        It "Should return False" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -Be $false
        }
        
    }

    Context "When Installed" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                . $FunctionPath @args | write-Output
            }
            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
        }
        BeforeEach {
            New-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -Force
            New-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized" -Force
            $I = Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized"
            $I | New-ItemProperty -Name 'Initialized' -Value 1 -PropertyType 'DWord' | Write-Verbose
            $I | New-ItemProperty -Name 'Test' -Value 1 -PropertyType 'DWord' | Write-Verbose
        }
        AfterEach {
            Remove-Item -Force -Recurse -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue
        }

        It "Should return True" {
            $Result = Invoke-ModuleFunctionStub
            $Result | Should -Be $true
        }
    }
}
