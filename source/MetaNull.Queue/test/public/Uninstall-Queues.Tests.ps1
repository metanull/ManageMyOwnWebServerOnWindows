Describe "Uninstall-Queues" -Tag "UnitTest" {

    
    Context "When calling Uninstall-Queues" {
        
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
            Function Test-QueuesInstalled {
                return $true
            }
            Function Lock-ModuleMutex {
                return $true
            }
            Function Unlock-ModuleMutex {
                return $true
            }
        }
        BeforeEach {
            $I = New-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized" -Force | Out-Null
            $I | New-ItemProperty -Name 'Initialized' -Value 1 -PropertyType 'DWord' | Out-Null
            
            Invoke-ModuleFunctionStub -Force
        }
        AfterEach {
            Remove-Item -Force -Recurse -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue
        }

        It "Registry key MetaNull.Queue should not exist" {
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
        It "Registry key MetaNull.Queue\Initialized should not exist" {
            Get-Item -Path "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\Initialized" -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }
}
