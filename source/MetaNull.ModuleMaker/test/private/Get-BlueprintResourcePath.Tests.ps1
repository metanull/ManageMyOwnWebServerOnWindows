Describe "Get-BlueprintResourcePath" -Tag "UnitTest" {
    Context "Calling from within a Test" {
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
        It "Should return the path to the resource directory" {
            $Expected = Join-Path (Split-Path (Split-Path $PSScriptRoot)) 'resource'
            $Result = Invoke-ModuleFunctionStub -Test
            $Result | Should -Be $Expected
        }
    }
}