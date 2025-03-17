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