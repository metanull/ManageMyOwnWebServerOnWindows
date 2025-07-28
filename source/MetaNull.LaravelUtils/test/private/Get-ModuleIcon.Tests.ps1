Describe "Testing private module function Get-ModuleIcon" -Tag "UnitTest" {
    Context "General context" {
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')
    
            # Create a Stub for the one module function to test
            Function Get-ModuleIcon {
                . $FunctionPath @args | write-Output
            }

            # Mock used module and system functions
            # N/A

            # Mock used module's variables
            $script:ModuleIcons = @{
                "Rocket" = if ($PSVersionTable.PSVersion.Major -ge 7) { "`u{1F680}" } else { "[START]" }
                "CheckMark" = if ($PSVersionTable.PSVersion.Major -ge 7) { "`u{1F197}" } else { "[OK]" }
                "UnknownIcon" = "?"
                "PlainText" = @{
                    "Rocket" = "[START]"
                    "CheckMark" = "[OK]"
                }
            }
            $script:UseEmojis = $PSVersionTable.PSVersion.Major -ge 7
        }

        It "Get-ModuleIcon -IconName 'Rocket'" {
            $Result = Get-ModuleIcon -IconName 'Rocket'
            $Result | Should -Not -BeNullOrEmpty
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $Result | Should -Be "`u{1F680}"
            } else {
                $Result | Should -Be "[START]"
            }
        }

        It "Get-ModuleIcon 'CheckMark'" {
            $Result = Get-ModuleIcon 'CheckMark'
            $Result | Should -Not -BeNullOrEmpty
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                $Result | Should -Be "`u{1F197}"
            } else {
                $Result | Should -Be "[OK]"
            }
        }

        It "Returns '?' for an unknown icon: Get-ModuleIcon -IconName 'UnknownIcon'" {
            $Result = Get-ModuleIcon -IconName 'UnknownIcon'
            $Result | Should -Be '?'
        }


    }
}