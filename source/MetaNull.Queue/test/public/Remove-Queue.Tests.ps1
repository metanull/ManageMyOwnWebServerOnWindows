Describe "Remove-Queue" -Tag "UnitTest" {
    Context "When queue does not exist" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                param([string]$QueueId)
                . $FunctionPath @args | write-Output
            }
            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
            Function Get-RegistryKeyProperties {
                param($RegistryKey)
                [hashtable]$Properties = @{}
                $RegistryKey | Select-Object -ExpandProperty Property | ForEach-Object {
                    $Properties += @{$_ = $RegistryKey.GetValue($_)}
                }
                return $Properties
            }
            Function Test-QueuesInstalled {
                return $false
            }
            Function Lock-ModuleMutex {
                return $true
            }
            Function Unlock-ModuleMutex {
                return $true
            }
            Function Get-Queue {
                return $null
            }
        }

        It "Should throw an error" {
            {Invoke-ModuleFunctionStub -QueueId (New-GUID) -Scope AllUsers} | Should -Throw
        }
    }

    Context "When queue exists" {
        
        BeforeAll {
            $ModuleRoot = $PSCommandPath | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent
            $ScriptName = $PSCommandPath | Split-Path -Leaf
            $Visibility = $PSCommandPath | Split-Path -Parent | Split-Path -Leaf
            $SourceDirectory = Resolve-Path (Join-Path $ModuleRoot "source\$Visibility")
            $TestDirectory = Resolve-Path (Join-Path $ModuleRoot "test\$Visibility")

            $FunctionPath = Join-Path $SourceDirectory ($ScriptName -replace '\.Tests\.ps1$', '.ps1')

            # Create a Stub for the module function to test
            Function Invoke-ModuleFunctionStub {
                param([string]$QueueId)
                . $FunctionPath @args | write-Output
            }
            Function Get-RegistryPath {
                param([string] $ChildPath)
                return "HKCU:\SOFTWARE\MetaNull\Tests\PowerShell\MetaNull.Queue\$ChildPath"
            }
            Function Get-RegistryKeyProperties {
                param($RegistryKey)
                [hashtable]$Properties = @{}
                $RegistryKey | Select-Object -ExpandProperty Property | ForEach-Object {
                    $Properties += @{$_ = $RegistryKey.GetValue($_)}
                }
                return $Properties
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
            Function Get-Queue {
                param([Parameter(Mandatory=$false)]$QueueId = '*')
                $Item = Get-Item -Path (Get-RegistryPath -ChildPath "Queues\$QueueId") 
                $Properties = Get-RegistryKeyProperties -RegistryKey $Item
                [PSCustomObject]@{
                    QueueId = $QueueId
                    Name = $Item | Split-Path -Leaf
                    Properties = (Get-RegistryKeyProperties -RegistryKey $Item)
                    Commands = @()
                    FirstCommandIndex = $null
                    LastCommandIndex = $null
                    RegistryKey = $Item
                }
            }

            Function GetDataIDs {
                return @(
                    '18baf574-4214-48a9-9dc9-5818ad8b7d49'
                    '0dc8c22b-64b7-4054-9392-ea68a516fe91'
                    '3e500d65-5685-4a67-9ed3-0f3fc297c6be'
                )
            }
            Function InitData {
                $Path = Get-RegistryPath -ChildPath 'Initialized'
                $I = New-Item -Path $Path -Force
                $I | New-ItemProperty -Name 'Initialized' -Value 1 -PropertyType 'DWord' | Out-Null
                $Path = Get-RegistryPath -ChildPath 'Queues'
                $I = New-Item -Path $Path -Force

                "Adding 3 Queues" | Write-Warning
                GetDataIDs | ForEach-Object {
                    $QueueName = $_
                    $QueueName | Write-Warning
                    $Path = Get-RegistryPath -ChildPath "Queues\$QueueName"
                    $Item = New-Item -Path $Path -Force
                    $Item | New-ItemProperty -Name Id -Value $QueueName -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name Description -Value $QueueName -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name Status -Value 'Iddle' -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name CreatedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name ModifiedDate -Value (Get-Date|ConvertTo-Json) -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name StartCount -Value 0 -PropertyType DWord | Out-Null
                    $Item | New-ItemProperty -Name FailureCount -Value 0 -PropertyType DWord | Out-Null
                    $Item | New-ItemProperty -Name Disabled -Value 0 -PropertyType DWord | Out-Null
                    $Item | New-ItemProperty -Name Suspended -Value 0 -PropertyType DWord | Out-Null
                    $Item | New-ItemProperty -Name DisabledDate -Value $null -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name SuspendedDate -Value $null -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name LastStartedDate -Value $null -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name LastFinishedDate -Value $null -PropertyType String | Out-Null
                    $Item | New-ItemProperty -Name Version -Value ([version]::new(0,0,0,0)|ConvertTo-JSon -Compress) -PropertyType String | Out-Null
                    
                    $Path = Get-RegistryPath -ChildPath "Queues\$QueueName\Commands"
                    $I = New-Item -Path $Path -Force
                }
            }
            Function ClearData {
                "Removing all Queues" | Write-Warning
                GetDataIDs | ForEach-Object {
                    $QueueName = $_
                    $QueueName | Write-Warning
                    $Path = Get-RegistryPath -ChildPath "Queues\$QueueName"
                    Remove-Item -Force -Recurse -Path $Path # -ErrorAction SilentlyContinue
                }
            }
        }
        BeforeEach {
            InitData
        }
        AfterEach {
            ClearData
        }
        AfterAll {
            ClearData
        }

        It "Should not throw" {
            $QueueNames = GetDataIDs
            $QueueName = $QueueNames[0]
            {
                Invoke-ModuleFunctionStub -QueueId $QueueName
            } | Should -Throw
        }
        It "Should not return anything" {
            $QueueNames = GetDataIDs
            $QueueName = $QueueNames[0]
            Invoke-ModuleFunctionStub -QueueId $QueueName | Should -BeNullOrEmpty
        }
        It "Remove queue should not exist anymore" {
            $QueueNames = GetDataIDs
            $QueueName = $QueueNames[0]
            Invoke-ModuleFunctionStub -QueueId $QueueName

            $Path = Get-RegistryPath -ChildPath "Queues\$QueueName"
            { Get-Item -Path $Path} | Should -Throw
        }
        It "Other queues should still exist (1)" {
            $QueueNames = GetDataIDs
            $QueueName = $QueueNames[0]
            Invoke-ModuleFunctionStub -QueueId $QueueName

            $OtherQueueName = $QueueNames[1]
            $Path = Get-RegistryPath -ChildPath "Queues\$OtherQueueName"
            { Get-Item -Path $Path} | Should -Not -BeNullOrEmpty
        }
        It "Other queues should still exist (2)" {
            $QueueNames = GetDataIDs
            $QueueName = $QueueNames[0]
            Invoke-ModuleFunctionStub -QueueId $QueueName

            $OtherQueueName = $QueueNames[2]
            $Path = Get-RegistryPath -ChildPath "Queues\$OtherQueueName"
            { Get-Item -Path $Path} | Should -Not -BeNullOrEmpty
        }
        It "Queue's Parent Registry key should exist after removing all queues" {
            $QueueNames = GetDataIDs
            $QueueNames | ForEach-Object {
                $QueueName = $_
                Invoke-ModuleFunctionStub -QueueId $QueueName
            }
            $Path = Get-RegistryPath -ChildPath "Queues"
            { Get-Item -Path $Path} | Should -Not -BeNullOrEmpty
        }
        It "Queue's Parent Registry key should have no children after removing all queues" {
            $QueueNames = GetDataIDs
            $QueueNames | ForEach-Object {
                $QueueName = $_
                Invoke-ModuleFunctionStub -QueueId $QueueName
            }
            $Path = Get-RegistryPath -ChildPath "Queues"
            { Get-ChildItem -Path $Path} | Should -BeNullOrEmpty
        }
    }
}
