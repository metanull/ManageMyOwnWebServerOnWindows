Function New-YamlDocument {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([pscustomobject])]
    param()
    [pscustomobject]@{
        Root = [System.Collections.ArrayList]::new()
    }
}
Function New-YamlStructure {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Name,
        [Parameter(Mandatory = $false, Position = 1)]
        [System.Collections.ArrayList] $Children = [System.Collections.ArrayList]::new()
    )
    [pscustomobject] @{
        Name = $Name
        Children = $Children
    }
}

Function New-YamlTag {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Default')]
        [Alias('String')]
        [string[]] $Value,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Integer')]
        [int] $Integer,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Float')]
        [Alias('Double')]
        [double] $Float,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Bool')]
        [bool] $Bool,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Binary')]
        [System.Byte[]] $Binary,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Null')]
        [switch] $IsNull,
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Timestamp')]
        [datetime] $Timestamp
    )
    switch($PSCmdlet.ParameterSetName) {
        'Integer' {
            $Value = $Integer
            $Type = 'int'
            $Multiline = $false
        }
        'Float' {
            $Value = $Float
            $Type = 'float'
            $Multiline = $false
        }
        'Bool' {
            $Value = $Bool
            $Type = 'bool'
            $Multiline = $false
        }
        'Binary' {
            $Value = [Convert]::ToBase64String($Binary)
            $Type = 'binary'
            $Multiline = $true
            $ChunkSize = 76
            $Chunks = @()
            for ($i = 0; $i -lt $Value.Length; $i += $ChunkSize) {
                $Chunks += $Value.Substring($i, [Math]::Min($ChunkSize, $Value.Length - $i))
            }
            $Value = $Chunks
        }
        'Null' {
            $Value = $null
            $Type = 'null'
            $Multiline = $false
        }
        'Timestamp' {
            $Value = $Timestamp|ConvertTo-JSon
            $Type = 'timestamp'
            $Multiline = $false
        }
        Default {
            $Value = $Value | Foreach-Object -Begin {$CountLines = 0} -Process {
                $CountLines ++
                $_.ToString().TrimStart()
            }
            $Type = 'str'
            $Multiline = $CountLines -gt 1
        }
    }
    [pscustomobject]@{
        Type = $Type
        Value = $Value
        Multiline = $Multiline
    }
}

Function Test-YamlDocument {

    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject] $YamlDocument
    )
    if($YamlDocument -isnot [pscustomobject]) {
        Write-Warning 'Invalid Yaml Document'
        return $false
    }
    if($null -eq $YamlDocument.Root) {
        Write-Warning 'Invalid Yaml Document: Root is null'
        return $false
    }
    if($YamlDocument.Root -isnot [System.Collections.ArrayList]) {
        Write-Warning 'Invalid Yaml Document: Root is invalid'
        return $false
    }
    return $true
}
Function Test-YamlStructure {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject] $YamlStructure
    )
    if($YamlStructure -isnot [pscustomobject]) {
        Write-Warning 'Invalid Yaml Structure'
        return $false
    }
    if([string]::IsNullOrEmpty($YamlStructure.Name)) {
        Write-Warning 'Invalid Yaml Structure: Name is invalid'
        return $false
    }
    if($YamlStructure.Children -isnot [System.Collections.ArrayList]) {
        Write-Warning 'Invalid Yaml Structure: Children is invalid'
        return $false
    }
    return $true
}
Function Test-YamlTag {
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [pscustomobject] $YamlTag
    )
    if($YamlTag -isnot [pscustomobject]) {
        Write-Warning 'Invalid Yaml Tag'
        return $false
    }
    if([string]::IsNullOrEmpty($YamlTag.Type)) {
        Write-Warning 'Invalid Yaml Tag: Type is invalid'
        return $false
    }
    if($null -eq $YamlTag.Value -and $YamlTag.Type -ne 'null') {
        Write-Warning 'Invalid Yaml Tag: Value is null'
        return $false
    }
    if($null -eq $YamlTag.MultilineBlockScalar -or $YamlTag.Multiline -notin @($true,$false)) {
        Write-Warning 'Invalid Yaml Tag: Multiline is no boolean'
        return $false
    }
    if($YamlTag.Type -notin @('str','int','bool','float','null','timestamp','binary')) {
        Write-Warning 'Invalid Yaml Tag: Type is invalid'
        return $false
    }
    if($YamlTag.Multiline -and $YamlTag.Type -notin ('str','binary')) {
        Write-Warning 'Invalid Yaml Tag: Multiline is only valid for str and binary type'
        return $false
    }
    return $true
}

<#

Ligne =
    Soit une valeur
        INDENT (!!type )?VALEUR$
    Soit un début de valeur multiligne
        INDENT (!!type )(>|-)[\+-]?$
    Soit une partie de valeur multiligne
        INDENT >> ==> NEWINDENT .*$
    Soit une fin de valeur multiligne
        INDENT << ==> ferme la valeur multiligne précédente, et parse la ligne courante
    Soit une valeur de type tableau
        INDENT - .*$ ==> Processe comme si c'était une nouvelle entrée => englobe toutes les lignes suivantes d'indent >>
                        à la fin, ajoute au tableau, et démarre le suivant qui sera un tableau au meme increment, ou un décréement (retour au niveau précédent)
    Soit une structure
        INDENT KEY: ==> Processe comme si c'était une nouvelle entrée => englobe toutes les lignes suivantes d'indent >>
                        à la fin, "set" la valeur, et démarre le suivant qui sera au meme increment , ou un décréement (retour au niveau précédent)


    ==> soit on démarre une nouvelle CLÉ/VALUE; soit on démarre un nouveau TABLEAU; soit on démarre une VALEUR MULTILIGNE; soit on capture une VALEUR EN LIGNE
#>

Function TrimComment {
    param(
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$String = ''
    )
    Process {
        if($null -eq $String -or [string]::IsNullOrEmpty($String) -or ($String -match '^ +(#.*)?$')) {
            return ''
        }
        if($String -is [System.Array]) {
            throw 'Invalid parameter, $String must be a string, Array received'
        }
        $Quoted = $null
        $EscapeNext = $false
        $Index = -1
        foreach($C in $String.ToCharArray()) {
            $Index ++
            # Test if next character is escaped
            if($C -eq "\") {
                if($EscapeNext) {
                    $EscapeNext = $false
                } else {
                    $EscapeNext = $true
                }
                continue
            }
            # Test if entering or leaving a quoted string
            if(-not $EscapeNext) {
                if($null -eq $Quoted) {
                    if($C -in '"','''' ) {
                        $Quoted = $C
                        continue
                    }
                } else {
                    if($C -eq $Quoted) {
                        $Quoted = $null
                        continue
                    }
                }
            }
            # Test if it is the beginning of a Comment
            if($null -eq $Quoted -and $C -eq '#') {
                # If so, remove the comment and break the loop
                $String = $String.Substring(0, $Index)
                break
            }
            # Reset the escape flag if we are not in a quoted string
            $EscapeNext = $false
        }
        # Return the final string
        #$String.TrimEnd() | Write-Output
        $String | Write-Output
    }
}
Function ProcessLine {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias('String')]
        [string]$Line
    )
    Begin {
        $Dex = [regex]::new(
            @(  '^('
                    '(%YAML (?<VersionDirective>[\d\.]+))'
                    '|'
                    '(%TAG (?<TagDirective>(!(?<TagName>[^!]+)! (?<TagValue>[^ ]+))+))'
                    '|'
                    '(?<DocumentStart>---( (!(?<DocumentTag>[^!]+))*)?)'
                    '|'
                    '(?<DocumentEnd>...)'
                ')$'
            ) -join ''
        )
        $Yex = [regex]::new(
            @(  '^'
                #'(?<VersionDirective>%YAML [\d\.]+$)?'
                #'(?<TagDirective>%TAG (!(?<TagName>[^!]+)! (?<TagValue>.+)$)*)?'
                #'(?<DocumentStart>---( (!(?<DocumentTag>[^!]+))*)?$)?'
                #'(?<DocumentEnd>...$)?'
                '(?<Indentation>[ ]*)'
                '(?<Structure>'
                    '(?<Array>- )'
                    '|'
                    '(?<QuotedKeyValuePair>(?<KeyQuote>["''])(?<QuotedKey>.*?)\k<KeyQuote>:( |$))?'
                    '|'
                    '(?<KeyValuePair>(?<Key>[^#@\|>%\?!\&\*][^#]+?):( |$))?'
                ')?'
                '(?<Tags>!!(?<CastTag>[^ ]+) )?'
                '(?<Value>'
                    '(?<MultilineBlockScalar>(?<BlockScalarStyle>[\|>])(?<BlockScalarChomp>[\+-])?(?<BlockScalarIndent>[1-9])?)'    # Block Scalar
                    '|'
                    '(?<FlowCollectionSequence>\[(?<FlowCollectionSequenceValue>.*)\])' # Array ([]) Flow Collection, single line
                    '|'
                    '(?<FlowCollectionMapping>\{(?<FlowCollectionMappingValue>.*)\})' # Object ({}) Flow Collection, single line
                    '|'
                    '(?<MultilineFlowCollection>(?<MultilineFlowCollectionType>[\[\{])(?<MultilineFlowCollectionValue>.*))' # Flow Collection, multiline line
                    '|'
                    '(?<QuotedFlowScalar>(?<QuotedFlowScalarType>["''])(?<QuotedFlowScalarValue>.*?)\k<QuotedFlowScalarType>)' # Flow Scalar, single line
                    '|'
                    '(?<MultilineQuotedFlowScalar>(?<MultilineQuotedFlowScalarType>["''])(?<MultilineQuotedFlowScalarValue>.*))' # Flow Scalar, multiline line
                    '|'
                    '(?<PlainScalar>(?<PlainScalarValue>.*))' # Flow Scalar, multiline line
                ')?'
                '$'
            ) -join ''
        )
    }
    Process {
        $OriginalLine = $Line

        # Parse the YAML line - checking for Document Level instructions
        $Parsed = $Dex.Match($OriginalLine)
        if(($Parsed.Success)) {
            # This is a document level line
            return [pscustomobject]@{
                Line = $OriginalLine
                Indentation = $null
                Empty = $false
                IsDocumentLevelLine = $true
                IsDocumentStart = $Parsed.Groups['DocumentStart'].Success
                IsDocumentEnd = $Parsed.Groups['DocumentEnd'].Success
                IsVersionDirective = $Parsed.Groups['VersionDirective'].Success
                IsTagDirective = $Parsed.Groups['TagDirective'].Success
                VersionDirective = $Parsed.Groups['VersionDirective'].Value
                TagDirective = "$(
                                for($td=0; $td -lt $Parsed.Groups['TagDirective'].Captures.Count; $td ++) {
                                    [pscustomobject]@{
                                        Name = $Parsed.Groups['TagName'].Captures[$td].Value
                                        Value = $Parsed.Groups['TagValue'].Captures[$td].Value
                                    }
                                })"
                DocumentTags = $Parsed.Groups['DocumentTag'].Captures.Value
                RawValue = $null
                RawLine = $OriginalLine
                RawParse = $Parsed.Groups
            }
        }

        # Trim and remove comments
        $Line = $Line  | TrimComment

        # Skip empty lines
        if([string]::IsNullOrEmpty($Line.Trim())) {
            return [pscustomobject]@{
                Line = $OriginalLine
                Indentation = ([regex]::new("^( *)")).Match($LineIndentation).Groups[0].Length
                Empty = $true
                IsDocumentLevelLine = $false
            }
        }

        # Parse the YAML line - Checking for YAML data
        $Parsed = $Yex.Match($Line)
        if(-not ($Parsed.Success)) {
            throw "Invalid Yaml Line: $Line - Regex Failed"
        }

        # Get the actual line indentation
        $LineIndentation = $Parsed.Groups['Indentation'].Length
        if($Parsed.Groups['Array'].Success) {
            # Array induces an extra identation ()"- " counting for 2)
            $LineIndentation = $Parsed.Groups['Array'].Index + $Parsed.Groups['Array'].Length
        }

        # Craft an object from the parsed line
        [pscustomobject]@{
            Line = $Line
            Indentation = $LineIndentation
            Empty = $false
            IsDocumentLevelLine = $false
            HasValue = $Parsed.Groups['Value'].Success
            IsSequence = $Parsed.Groups['Array'].Success
            IsMapping = (
                $Parsed.Groups['KeyValuePair'].Success -or `
                $Parsed.Groups['QuotedKeyValuePair'].Success
            )
            IsMultiline = (
                $Parsed.Groups['MultilineBlockScalar'].Success -or `
                $Parsed.Groups['MultilineFlowCollection'].Success -or `
                $Parsed.Groups['MultilineQuotedFlowScalar'].Success 
            )
            IsMultilineByIndentation = (
                $Parsed.Groups['PlainScalar'].Success
            )
            IsBlockScalar = $Parsed.Groups['MultilineBlockScalar'].Success
            IsFlowCollection = (
                $Parsed.Groups['FlowCollectionSequence'].Success -or `
                $Parsed.Groups['FlowCollectionMapping'].Success -or `
                $Parsed.Groups['MultilineFlowCollection'].Success
            )
            IsFlowScalar = (
                $Parsed.Groups['QuotedFlowScalar'].Success -or `
                $Parsed.Groups['MultilineQuotedFlowScalar'].Success
            )
            IsPlainScalar = $Parsed.Groups['PlainScalar'].Success
            Key = [pscustomobject]@{
                Value = "$( if($Parsed.Groups['KeyValuePair'].Success) {
                                $Parsed.Groups['Key'].Value
                            } elseif($Parsed.Groups['QuotedKeyValuePair'].Success) {
                                $Parsed.Groups['QuotedKey'].Value
                            } else {
                                $null
                            })" 
                        #$Parsed.Groups['Key'].Value
                Quote = "$( if($Parsed.Groups['QuotedKeyValuePair'].Success) {
                                $Parsed.Groups['KeyQuote'].Value
                            } else {
                                $null
                            })"
                        #$Parsed.Groups['KeyQuote'].Value
            }
            Cast = $Parsed.Groups['CastTag'].Value
            BlockScalar = [PSCustomObject]@{
                Style = $Parsed.Groups['BlockScalarStyle'].Value
                Chomp = $Parsed.Groups['BlockScalarChomp'].Value
                Indent = $Parsed.Groups['BlockScalarIndent'].Value
            }
            FlowCollection = [PSCustomObject]@{
                Type = "$(  if($Parsed.Groups['FlowCollectionSequence'].Success) {
                                '[]'
                            } elseif($Parsed.Groups['FlowCollectionMapping'].Success) {
                                '{}'
                            } elseif($Parsed.Groups['MultilineFlowCollectionType'].Success) {
                                if($Parsed.Groups['MultilineFlowCollectionType'].Value -eq '[') {
                                    '[]'
                                } elseif($Parsed.Groups['MultilineFlowCollectionType'].Value -eq '{') {
                                    '{}'
                                } else {
                                    $null
                                }
                            } else {
                                $null
                            })"
                Value = "$( if($Parsed.Groups['FlowCollectionSequence'].Success) {
                            $Parsed.Groups['FlowCollectionSequenceValue'].Value
                        } elseif($Parsed.Groups['FlowCollectionMapping'].Success) {
                            $($Parsed.Groups['FlowCollectionMappingValue'].Value)
                        } elseif($Parsed.Groups['MultilineFlowCollectionType'].Success) {
                            $($Parsed.Groups['MultilineFlowCollectionValue'].Value)
                        } else {
                            $null
                        })"
                        #"$($Parsed.Groups['FlowCollectionSequenceValue'].Value)$($Parsed.Groups['FlowCollectionMappingValue'].Value)$($Parsed.Groups['MultilineFlowCollectionValue'].Value)"
                MultiLine = $Parsed.Groups['MultilineFlowCollection'].Success
                MultilineEnder = "$(
                            if($Parsed.Groups['FlowCollectionSequence'].Success -or $Parsed.Groups['MultilineFlowCollectionType'].Value -eq '[') {
                                ']'
                            } elseif($Parsed.Groups['FlowCollectionMapping'].Success -or $Parsed.Groups['MultilineFlowCollectionType'].Value -eq '{') {
                                '}'
                            } else {
                                $null
                            })"
            }
            FlowScalar = [PSCustomObject]@{
                Type =  "$(
                            if($Parsed.Groups['QuotedFlowScalar'].Success) {
                                $Parsed.Groups['QuotedFlowScalarType'].Value
                            } elseif($Parsed.Groups['MultilineQuotedFlowScalar'].Success) {
                                $Parsed.Groups['MultilineQuotedFlowScalarType'].Value
                            } else {
                                $null
                            })"
                        #"$($Parsed.Groups['QuotedFlowScalarType'].Value)$($Parsed.Groups['MultilineQuotedFlowScalarType'].Value)"
                Value = "$(
                            if($Parsed.Groups['QuotedFlowScalar'].Success) {
                                $Parsed.Groups['QuotedFlowScalarValue'].Value
                            } elseif($Parsed.Groups['MultilineQuotedFlowScalar'].Success) {
                                $Parsed.Groups['MultilineQuotedFlowScalarValue'].Value
                            } else {
                                $null
                            }
                        )"
                        #"$($Parsed.Groups['QuotedFlowScalarValue'].Value)$($Parsed.Groups['MultilineQuotedFlowScalarValue'].Value)"
                MultiLine = $Parsed.Groups['MultilineQuotedFlowScalar'].Success
                MultilineEnder = $Parsed.Groups['MultilineQuotedFlowScalarType'].Value
            }
            PlainScalar = [PSCustomObject]@{
                Value = "$($Parsed.Groups['PlainScalarValue'].Value)"
            }
            RawValue = "$($Parsed.Groups['Value'].Value)"
            RawLine = $OriginalLine
            RawParse = $Parsed.Groups
            <#
            KeyValuePair = $Parsed.Groups['KeyValuePair'].Success
            Array = $Parsed.Groups['Array'].Success
            Multiline = $Parsed.Groups['MultilineBlockScalar'].Success
            BlockScalarStyle = $Parsed.Groups['BlockScalarStyle'].Value
            BlockScalarChomp = $Parsed.Groups['BlockScalarChomp'].Value
            BlockScalarIndent = $Parsed.Groups['BlockScalarIndent'].Value
            QuotedFlowScalar = $Parsed.Groups['QuotedFlowScalar'].Success
            QuotedFlowScalarType = $Parsed.Groups['QuotedFlowScalarType'].Value
            QuotedFlowScalarValue = $Parsed.Groups['QuotedFlowScalarValue'].Value
            MultilineQuotedFlowScalar = $Parsed.Groups['MultilineQuotedFlowScalar'].Success
            MultilineQuotedFlowScalarType = $Parsed.Groups['MultilineQuotedFlowScalarType'].Value
            MultilineQuotedFlowScalarValue = $Parsed.Groups['MultilineQuotedFlowScalarValue'].Value
            Key = $Parsed.Groups['Key'].Value
            KeyQuote = $Parsed.Groups['KeyQuote'].Value
            Cast = $Cast
            # Parsed = $Parsed
            #>
        } | Write-Output
    }
}
<#
Function ConvertFrom-Yaml {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowEmptyString()]
        [string[]] $Lines
    )
    Begin {
        Function ProcessParsedLines {
            param(
                [System.Collections.ArrayList] $ParsedLines
            )
            # Get the first line to determine the indentation level
            for($i = 0; $i -lt $ParsedLines.Count; $i ++) {
                if($ParsedLines[$i].Empty) {
                    continue
                } else {
                    $FirstLineIndex = $i
                }
            }
            if($null -eq $FirstLineIndex) {
                Write-Warning 'No valid Yaml line found'
                return
            }
            $FirstLine = $ParsedLines[$FirstLineIndex]
            
            $IndentationStack = [System.Collections.ArrayList]::new()
            $IndentationStack.Add($FirstLine.Indentation) | Out-Null
            
            if($FirstLine.Array) {
                # Collect each array item
                $ArrayIndentation = $FirstLine.Indentation
                $ArrayItems = [System.Collections.ArrayList]::new()
                $CurrentItem = [System.Collections.ArrayList]::new()
                for($i = $FirstLineIndex; $i -lt $ParsedLines.Count; $i ++) {
                    if($ParsedLines[$i].Indentation -lt $ArrayIndentation) {
                        # End of the array
                        if($CurrentItem.Count -gt 0) {
                            # Push the current item to the array
                            $ArrayItems.Add($CurrentItem) | Out-Null
                            $CurrentItem = [System.Collections.ArrayList]::new()
                        }
                        break
                    } elseif($ParsedLines[$i].Indentation -eq $ArrayIndentation -and $ParsedLines[$i].Array) {
                        # Begins a new item in the array
                        if($CurrentItem.Count -gt 0) {
                            # Push the current item to the array
                            $ArrayItems.Add($CurrentItem) | Out-Null
                            $CurrentItem = [System.Collections.ArrayList]::new()
                        }
                        # Item value may be INLINE (String, array or FLOW SCALAR), MULTILINE (BLOCK SCALAR), or an OBJECT to further process
                        if($ParsedLines[$i].QuotedFlowScalar) {
                            # Handle FLOW SCALAR
                            if($ParsedLines[$i].QuotedFlowScalarValue.StartsWith())
                            # Handle inline value
                            switch($ParsedLines[$i].Cast) {
                                'int' {
                                    $InlineObject = [int]::parse($ParsedLines[$i].QuotedFlowScalarValue)
                                }
                                'float' {
                                    $InlineObject = [float]::parse($ParsedLines[$i].QuotedFlowScalarValue)
                                }
                                'bool' {
                                    if($ParsedLines[$i].QuotedFlowScalarValue -in 'y','yes','on','true','1') {
                                        $InlineObject = $true
                                    } elseif($ParsedLines[$i].QuotedFlowScalarValue -in 'n','no','off','false','0') {
                                        $InlineObject = $false
                                    } else {
                                        $InlineObject = [bool]::parse($ParsedLines[$i].QuotedFlowScalarValue)
                                    }
                                }
                                'null' {
                                    $InlineObject = $null
                                }
                                'timestamp' {
                                    $InlineObject = [datetime]("""$($ParsedLines[$i].QuotedFlowScalarValue)"""|ConvertFrom-Json)
                                }
                                'binary' {
                                    $InlineObject = [System.Convert]::FromBase64String($ParsedLines[$i].QuotedFlowScalarValue)
                                }
                                default {
                                    $InlineObject = $ParsedLines[$i].QuotedFlowScalarValue
                                    if($InlineObject -match '^\[.*\]$') {
                                        try {
                                            $J = $InlineObject | ConvertFrom-Json
                                            $InlineObject = $J
                                        } catch {
                                            # Not a valid JSON, keep the original value
                                        }
                                    }
                                }
                            }
                            $CurrentItem.Add($InlineObject) | Out-Null
                        } elseif($ParsedLines[$i].Multiline) {
                            # Handle BLOCK SCALAR
                            
                            # Get all subsequent lines until a decrease in indentation is found
                            $MultilineLines = [System.Collections.ArrayList]::new()
                            $MultilineCast = $ParsedLines[$i].Cast
                            $BlockScalarStyle = $ParsedLines[$i].BlockScalarStyle
                            $BlockScalarChomp = $ParsedLines[$i].BlockScalarChomp
                            $BlockScalarIndent = $ParsedLines[$i].BlockScalarIndent

                            if($i -eq $ParsedLines.Count - 1) {
                                throw "Invalid Yaml Line: Multiline value starting on the last line"
                            }
                            # Get the multiline block indentation from its first line
                            $MultilineIndentation = $ParsedLines[$i + 1].Indentation
                            if($BlockScalarIndent) {
                                # First line of the multiline block has a declared extra indentation
                                $MultilineIndentation -= $BlockScalarIndent
                            }
                            # Get the multiline block, striping leading indentation
                            for(; $i -lt $ParsedLines.Count; $i ++) {
                                if($ParsedLines[$i].Indentation -lt $ArrayIndentation) {
                                    # End of the multiline found
                                    break
                                }
                                # Strips out the leading indentation
                                $MultilineLines.Add($ParsedLines[$i].Line.Substring($MultilineIndentation)) | Out-Null
                            }
                            # Process the multiline block according to Style and Chomp preferences
                            if($BlockScalarStyle -eq '|') {
                                # Multiline block with literal style => preserve new lines
                                # https://yaml-multiline.info/

                                # TO DO
                            } elseif($BlockScalarStyle -eq '>') {
                                # Multiline block with folded style => replace new lines with space
                                # https://yaml-multiline.info/

                                # TO DO
                            }
                            if($BlockScalarChomp -eq '+') {
                                # Multiline block with "KEEP" chomping style
                                # https://yaml-multiline.info/

                                # TO DO
                            } elseif($BlockScalarChomp -eq '-') {
                                # Multiline block with "STRIP" chomping style
                                # https://yaml-multiline.info/

                                # TO DO
                            } else {
                                # Multiline block with "CLIP" chomping style
                                # https://yaml-multiline.info/

                                # TO DO
                            }
                            # Cast the multiline block to the requested type (only 'binary' or 'str' are supported/Defined)
                            if($MultilineCast -eq 'binary') {
                                # Multiline block with base64 encoded binary content => strip spaces and convert to byte array
                                $CurrentItem.Add([System.Convert]::FromBase64String((($MultilineLines -join '') -replace '\s+'))) | Out-Null
                            } else {
                                $CurrentItem.Add($MultilineLines) | Out-Null
                            }
                        } else {
                            # Push the current line to the item
                            $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                        }
                    } else {
                        # Push the current line to the item
                        $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                    }
                }

                # Process each ArrayItem
                $Object = [System.Collections.ArrayList]::new()
                for($k = 0; $k -lt $ArrayItems.Count; $k ++) {
                    $Object.Add((ProcessParsedLines -ParsedLines $ArrayItems[$k]))
                }
                return $Object
            } elseif($FirstLine.KeyValuePair) {
                # Collect each key/value item
                $ArrayIndentation = $FirstLine.Indentation
                $ArrayItems = [System.Collections.ArrayList]::new()
                $CurrentItem = [System.Collections.ArrayList]::new()
                $KeyItems = [System.Collections.ArrayList]::new()
                $CurrentKey = $FirstLine.Key
                for($i = $FirstLineIndex; $i -lt $ParsedLines.Count; $i ++) {
                    if($ParsedLines[$i].Indentation -lt $ArrayIndentation) {
                        # End of the array
                        if($CurrentItem.Count -gt 0) {
                            # Push the current item to the array
                            $ArrayItems.Add($CurrentItem) | Out-Null
                            $KeyItems.Add($CurrentKey) | Out-Null
                            $CurrentItem = [System.Collections.ArrayList]::new()
                            $CurrentKey = $null
                        }
                        break
                    } elseif($ParsedLines[$i].Indentation -eq $ArrayIndentation -and $ParsedLines[$i].KeyValuePair) {
                        # Begins a new item in the array
                        if($CurrentItem.Count -gt 0) {
                            # Push the current item to the array
                            $ArrayItems.Add($CurrentItem) | Out-Null
                            $KeyItems.Add($CurrentKey) | Out-Null
                            $CurrentItem = [System.Collections.ArrayList]::new()
                            $CurrentKey = $ParsedLines[$i].Key
                        }
                        # Push the current line to the item
                        $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                    } else {
                        # Push the current line to the item
                        $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                    }
                }

                # Process each ArrayItem
                $Object = [System.Collections.Hashtable]::new()
                for($k = 0; $k -lt $ArrayItems.Count; $k ++) {
                    $Object.Add($KeyItems[$k], (ProcessParsedLines -ParsedLines $ArrayItems[$k]))
                }
                return $Object
            } else {
                # Process as a normal line
                return $ParsedLines | Foreach-Object -Process {
                    $_.Line.TrimEnd()
                }
            }
        }
    }
    Process {
        
        $ParsedLines = [System.Collections.ArrayList]::new()
        foreach($Line in $Lines) {
            $Parsed = $Line | ProcessLine
            if($Parsed) {
                $ParsedLines.Add($Parsed) | Out-Null
            }
        }
        if($ParsedLines.Count -eq 0) {
            Write-Warning 'No valid Yaml line found'
            return
        }
        
        # Get the first line to determine the indentation level
        $FirstLine = $ParsedLines[0]
        $IndentationStack = [System.Collections.ArrayList]::new()
        $IndentationStack.Add($FirstLine.Indentation) | Out-Null
        if($FirstLine.Array) {
            # Collect each array item
            $ArrayIndentation = $FirstLine.Indentation
            $ArrayItems = [System.Collections.ArrayList]::new()
            $CurrentItem = [System.Collections.ArrayList]::new()
            for($i = 0; $i -lt $ParsedLines.Count; $i ++) {
                if($ParsedLines[$i].Indentation -lt $ArrayIndentation) {
                    # End of the array
                    if($CurrentItem.Count -gt 0) {
                        # Push the current item to the array
                        $ArrayItems.Add($CurrentItem) | Out-Null
                        $CurrentItem = [System.Collections.ArrayList]::new()
                    }
                    break
                } elseif($ParsedLines[$i].Indentation -eq $ArrayIndentation -and $ParsedLines[$i].Array) {
                    # Begins a new item in the array
                    if($CurrentItem.Count -gt 0) {
                        # Push the current item to the array
                        $ArrayItems.Add($CurrentItem) | Out-Null
                        $CurrentItem = [System.Collections.ArrayList]::new()
                    }
                    # Push the current line to the item
                    $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                } else {
                    # Push the current line to the item
                    $CurrentItem.Add($ParsedLines[$i]) | Out-Null
                }
            }

            # Process each ArrayItem
            $ArrayItems


        }

            if($Parsed.Array) {
                # Process as an array
                $Array = @()
                $Array += $Parsed.Line
                $Array | ConvertFrom-Yaml
            } elseif($Parsed.KeyValuePair) {
                # Process as a key-value pair
                $Key = $Parsed.Key
                $Value = $Parsed.QuotedFlowScalarValue
                [pscustomobject]@{
                    Key = $Key
                    Value = $Value
                } | Write-Output
            } else {
                # Process as a normal line
                Write-Output $Parsed.Line
            }
        }
    }
}
#>

# Example
# . E:\ManageMyOwnWebServerOnWindows\source\MetaNull.Pipeline\source\public\Yaml.ps1 
$yml = @('Step:','- Task:','  Name: "Build"','  Path: .','#Next step','- Task:','  Name: "Deploy"','  Script: |','         Get-Date') 
$yml | ProcessLine | Select Line,Indentation,Depth,Key,Cast,QuotedFlowScalarValue,MultilineQuotedFlowScalarValue,Multiline,BlockScalarStyle,BlockScalarChomp,BlockScalarIndent,MultilineQuotedFlowScalarType | ft