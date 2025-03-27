

Describe "Testing private module function Invoke-Script" -Tag "UnitTest" {

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

        Mock Start-Sleep {
            # Do nothing
        }

        Function Invoke-VisualStudioOnlineString {
            param(
                [ref]$VsoState
            )
            $VsoState.Value = [pscustomobject]@{
                Result = [pscustomobject]@{
                    Message = 'Done'
                    Result = 'Succeeded'
                }
                Variable = @()
                Secret = @()
                Path = @()
                Upload = @()
                Log = @()
            }
        }
    }

    Context "When calling the function with a simple command" {
        BeforeAll {
        }

        It "Should work" {
            $Result = Invoke-ModuleFunctionStub -Commands '"hello"|Write-Output'
            $Result.Value.Result.Message | Should -Be 'Done'
            $Result.Value.Result.Result | Should -Be 'Succeeded'
            $Result.Value.Variable.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Value.Secret.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Value.Path.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Value.Upload.GetType().FullName | Should -Be 'System.Object[]'
            $Result.Value.Log.GetType().FullName | Should -Be 'System.Object[]'
        }
    }
}