Describe "Testing private module function Get-DevIcon" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Get-DevIcon {
                . $FunctionPath @args | write-Output
            }

            # Mock other module and system functions
            Function Get-ModuleIcon {
                # N/A
            }
            Mock Get-ModuleIcon {
                param($IconName)
                switch ($IconName) {
                    "Rocket" { return "[START]" }
                    "CheckMark" { return "[OK]" }
                    default { return '?' }
                }
            }

            # Mock used module's variables
            # N/A
        }

        It "Get-DevIcon -IconName 'Rocket'" {
            $Result = Get-DevIcon -IconName 'Rocket'
            $Result | Should -Be "[START]"
        }

        It "Get-DevIcon 'CheckMark'" {
            $Result = Get-DevIcon 'CheckMark'
            $Result | Should -Be "[OK]"
        }

    }
}