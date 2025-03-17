# Mock Module Initialization, create the test registry key
$PSDriveRoot = 'HKCU:\SOFTWARE\MetaNull\PowerShell.Tests\MetaNull.Queue'
New-Item -Force -Path $PSDriveRoot\Queues -ErrorAction SilentlyContinue  | Out-Null
$MetaNull = @{
    Queue = @{
        PSDriveRoot = $PSDriveRoot
        Lock = New-Object Object
        Drive = New-PSDrive -Name 'MetaNull' -Scope Script -PSProvider Registry -Root $PSDriveRoot
    }
}
# Generate TestData
$TestData = @(
    @{
        Queue = @{
            Id = (New-Guid)
            Name = 'NAME:1'
            Description = 'DESCRIPTION:1'
            Status = 'Iddle'
        }
        Commands = @(
            @{
                Index = 1
                Name = 'Test-Command:1#1'
                Command = 'Hello'
            }
            @{
                Index = 2
                Name = 'Test-Command:1#2'
                Command = 'World'
            }
        )
    }
    @{
        Queue = @{
            Id = (New-Guid)
            Name = 'NAME:2'
            Description = 'DESCRIPTION:2'
            Status = 'Iddle'
        }
        Commands = @(
            @{
                Index = 1
                Name = 'Test-Command:2#1'
                Command = 'Hello'
            }
            @{
                Index = 2
                Name = 'Test-Command:2#2'
                Command = 'World'
            }
            @{
                Index = 3
                Name = 'Test-Command:2#3'
                Command = '!'
            }
        )
    }
)