Describe "Test-IsAdministrator" -Tag "UnitTest" {
    Context "Depending if current use is an administrator" {
        BeforeAll {
            $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\public")
            $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
            $Script = Join-Path $ScriptDirectory $ScriptName
    
            Function Test-IsAdministrator {
                . $Script @args | write-Output
            }
        }

        It "Should return TRUE or FALSE depending on the user" {
            $Result = Test-IsAdministrator
            $Result | Should -Be ((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        }
    }
}