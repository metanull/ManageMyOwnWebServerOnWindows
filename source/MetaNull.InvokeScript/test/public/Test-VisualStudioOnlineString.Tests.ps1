Describe "Testing public module function Test-VisualStudioOnlineString" -Tag "UnitTest" {
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
    }
    Context "When ConvertFrom-VisualStudioOnlineString returns something" {
        BeforeAll {
            Function ConvertFrom-VisualStudioOnlineString {
                return @{something = $true}
            }
        }

        It "Should return true" {
            $Result = Invoke-ModuleFunctionStub -String 'Whatever'
            $Result | Should -BeTrue
        }
    }

    Context "When ConvertFrom-VisualStudioOnlineString returns nothing" {
        BeforeAll {
            Function ConvertFrom-VisualStudioOnlineString {
                return
            }
        }

        It "Should return false" {
            $Result = Invoke-ModuleFunctionStub -String 'Whatever'
            $Result | Should -BeFalse
        }
    }
}