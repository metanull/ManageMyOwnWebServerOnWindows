[CmdletBinding(DefaultParameterSetName='Default')]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $String
)
Begin {
    $VisualStudioOnlineExpressions = @{
        Command = '^##vso\[(?<command>[\S]+)(?<properties>[^\]]*)\](?<line>.*)$'
        Format = '^##\[(?<format>group|endgroup|section|warning|error|debug|command)\](?<line>.*)$'
    }
}
Process {
    $VSO = $null

    $VisualStudioOnlineExpressions = $VisualStudioOnlineExpressions.GetEnumerator() | Sort-Object -Property Name
    
    $VisualStudioOnlineExpressions | ForEach-Object {
        $regex = [regex]::new($_)
        $VSO = $regex.Match($String)
        if ($VSO.Success) {
            break    
        }
    }
    if(-not $VSO.Success) {
        return
    }
    

}