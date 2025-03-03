Describe "Test-IsAdministrator" -Tag "UnitTest" {
    Context "When is not administrator" {
        BeforeAll {
            $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
            $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
            $Script = Join-Path $ScriptDirectory $ScriptName
    
            Function Test-IsAdministrator {
                . $Script @args | write-Output
            }
        }

        It "Should return FALSE" {
            $Result = Test-IsAdministrator
            $Result | Should -Be $false
        }
    }
}