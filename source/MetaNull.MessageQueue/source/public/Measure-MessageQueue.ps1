@{
    Id = [guid]::NewGuid()
    Name = 'Queue 1'
    Size = 42
    Free = 958
    FirstMessage = 1
    FirstMessageDate = ($Date|ConvertFrom-JSon)
    LastMessage = 42
    LastMessageDate = ($Date|ConvertFrom-JSon)
}