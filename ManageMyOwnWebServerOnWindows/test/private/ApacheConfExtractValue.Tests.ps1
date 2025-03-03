Describe "ApacheConfExtractValue" -Tag "UnitTest" {
    BeforeAll {

        $ScriptDirectory = Resolve-Path (Join-Path ($PSCommandPath | Split-Path) "..\..\source\private")
        $ScriptName = (Split-Path $PSCommandPath -Leaf) -replace '\.Tests\.ps1$', '.ps1'
        $Script = Join-Path $ScriptDirectory $ScriptName

        Function ApacheConfExtractValue {
            param(
                $Statement,
                [parameter(ValueFromPipeline = $true)]
                $Conf
            )
            $Conf | . $Script -Statement $Statement | write-Output
        }
    }

    Context "When no space, quote, tab, or comment" {
        It "Should return a string" {
            $Result = @('ServerRoot C:/Apache24') | . $Script -Statement 'ServerRoot'
            $Result | Should -BeOfType [String]
        }
        It "Should return C:/Apache24" {
            $Result = @('ServerRoot C:/Apache24') | . $Script -Statement 'ServerRoot'
            $Result | Should -Be "C:/Apache24"
        }
    }
    Context "When multiple matches, quote and comment" {
        It "Should return an array of length 2" {
            $Result = @('ServerRoot C:/Apache24', 'ServerRoot "C:/Apache 24"', '# ServerRoot C:/Apache24') | . $Script -Statement 'ServerRoot'
            $Result.Count | Should -Be 2
        }
        It "Should return C:/Apache24 twice" {
            $Result = @('ServerRoot C:/Apache24', 'ServerRoot "C:/Apache 24"', '# ServerRoot C:/Apache24') | . $Script -Statement 'ServerRoot'
            $Result[0] | Should -Be "C:/Apache24"
            $Result[1] | Should -Be "C:/Apache 24"
        }
    }
    Context "When quote and space" {
        It "Should return a string" {
            $Result = @('ServerRoot "C:/Apache 24"') | . $Script -Statement 'ServerRoot'
            $Result | Should -BeOfType [String]
        }
        It "Should return C:/Apache24" {
            $Result = @('ServerRoot "C:/Apache 24"') | . $Script -Statement 'ServerRoot'
            $Result | Should -Be "C:/Apache 24"
        }
    }
    Context "When comment" {
        It "Should return a string" {
            $Result = @('ServerRoot C:/Apache24 #Hello') | . $Script -Statement 'ServerRoot'
            $Result | Should -BeOfType [String]
        }
        It "Should return C:/Apache24" {
            $Result = @('ServerRoot C:/Apache24  #Hello') | . $Script -Statement 'ServerRoot'
            $Result | Should -Be "C:/Apache24"
        }
    }
    Context "When spaces and comment" {
        It "Should return a string" {
            $Result = @('  ServerRoot  C:/Apache24  #Hello  ') | . $Script -Statement 'ServerRoot'
            $Result | Should -BeOfType [String]
        }
        It "Should return C:/Apache24" {
            $Result = @('  ServerRoot  C:/Apache24  #Hello  ') | . $Script -Statement 'ServerRoot'
            $Result | Should -Be "C:/Apache24"
        }
    }
    Context "When spaces, quotes and comment" {
        It "Should return a string" {
            $Result = @('  ServerRoot  "C:/Apache 24"  #Hello  ') | . $Script -Statement 'ServerRoot'
            $Result | Should -BeOfType [String]
        }
        It "Should return C:/Apache24" {
            $Result = @('  ServerRoot  "C:/Apache 24"  #Hello  ') | . $Script -Statement 'ServerRoot'
            $Result | Should -Be "C:/Apache 24"
        }
    }
}