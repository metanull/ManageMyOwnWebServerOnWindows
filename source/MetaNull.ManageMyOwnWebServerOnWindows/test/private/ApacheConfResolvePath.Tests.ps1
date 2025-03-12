Describe "ApacheConfReplaceConstant" -Tag "UnitTest" {
    
    BeforeAll {

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName

        Function ApacheConfResolvePath {
            param(
                $ServerRoot,
                [parameter(ValueFromPipeline = $true)]
                $Path
            )
            $Path | . $Script -ServerRoot $ServerRoot | write-Output
        }
    }
    Context "When rooted path" {
        It "Should return the original path" {
            $Value = 'C:/Apache24/home/dir'
            $ServerRoot = 'C:/Apache24'
            $Expected = "C:/Apache24/home/dir"

            $Result = $Value | ApacheConfResolvePath -ServerRoot $ServerRoot
            $Result | Should -BeExactly $Expected
        }
    }
    Context "When not rooted path" {
        It "Should return the absolute path" {
            $Value = 'home/dir'
            $ServerRoot = 'C:/Apache24'
            $Expected = "C:\Apache24\home\dir"

            $Result = $Value | ApacheConfResolvePath -ServerRoot $ServerRoot
            $Result | Should -BeExactly $Expected
        }
    }
}