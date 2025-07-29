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
                    '(?<MultilineBlockScalar>(?<BlockScalarStyle>[\|>])(?<BlockScalarChomp>[\+-])?(?<BlockScalarIndent>[1-9])?)'    # Block Scalar, always multiline
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
                HasDocumentTags = $Parsed.Groups['DocumentTag'].Success
                DocumentTags = $Parsed.Groups['DocumentTag'].Captures.Value
                RawValue = $null
                RawLine = $OriginalLine
                RawParse = $Parsed.Groups
            }
        }

        # Trim and remove comments
        Write-Debug "   > ORIGINAL: ``$($OriginalLine)``"
        Write-Debug "   > NOT TRIMMED: ``$($Line)``"
        $Line = $Line  | TrimComment
        Write-Debug "   > TRIMMED: ``$($Line)``"

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
                $Parsed.Groups['MultilineFlowCollection'].Success -or `
                $Parsed.Groups['MultilineQuotedFlowScalar'].Success 
            )
            IsMultilineByIndentation = (
                $Parsed.Groups['MultilineBlockScalar'].Success -or `
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
            
        } | Write-Output
    }
}

Function ProcessAllLines {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyString()]
        [string[]]$YamlLines,

        [int]$Identation = 0
    )
    Begin {
        Function CountLeadingSpaces {
            param(
                [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
                [AllowEmptyString()]
                [string]$Line,

                [switch]$IgnoreSequence
            )
            Process {
                if($IgnoreSequence.IsPresent -and $IgnoreSequence) {
                    $rx = [regex]::new('^(?<Indentation>[ ]+)')
                } else {
                    $rx = [regex]::new('^(?<Indentation>[ ]+)?(?<Sequence>- )?')
                }
                $r = $rx.Match($Line)
                if($r.Groups['Sequence'].Success) {
                    return $r.Groups['Indentation'].Length + $r.Groups['Sequence'].Length
                } elseif($r.Groups['Indentation'].Success) {
                    return $r.Groups['Indentation'].Length
                } else {
                    return $null
                }
            }
        }
    }
    Process {
        $Documents = [System.Collections.ArrayList]::new()
        
        $Header = $true
        $CurrentDocument = $null
        for($k = 0; $k -lt $YamlLines.Length; $k ++) {
            Write-Debug "Yaml line $($k): ``$($YamlLines[$k])``"
            if($Header -and ($_ -eq [string]::empty -or $_ -match '^#')) {
                # Skip Leading empty lines and comments in the document header
                Write-Debug "Yaml line $($k): Skipping empty or comment line"
                continue
            }

            # Parse the current line
            $Parsed = $YamlLines[$k] | ProcessLine

            #"PARSED: " | write-Warning
            #$Parsed |  Write-Error

            # Line is an explicit document end
            if($Parsed.IsDocumentEnd) {
                Write-Debug "Yaml line $($k): Document End found"
                if($null -ne $CurrentDocument) {
                    Write-Debug "Yaml line $($k): Adding current document to the output"
                    # Add the current document to the list
                    $Documents.Add($CurrentDocument) | Out-Null
                }
                Write-Debug "Yaml line $($k): Resetting the current document"
                # Reset the current document
                $CurrentDocument = $null
                $Header = $true
                continue
            }
            # Line is a document level directive
            if($Parsed.IsDocumentLevelLine) {
                if(-not $Header) {
                    throw "Yaml line $($k): Yaml directive found in the body"
                }
                # A document header directive was found, process it
                if($Parsed.IsDocumentStart) {
                    Write-Debug "Yaml line $($k): Document Start found"
                    # An explicit document start
                    if($null -ne $CurrentDocument) {
                        Write-Debug "Yaml line $($k): Adding current document to the output"
                        # Add the current document to the list
                        $Documents.Add($CurrentDocument) | Out-Null
                    }
                    Write-Debug "Yaml line $($k): Resetting the current document"
                    # Reset the current document
                    $Header = $true
                    $CurrentDocument = New-Object Object
                    if($Parsed.HasDocumentTags) {
                        Write-Debug "Yaml line $($k): Document Tags: $($Parsed.DocumentTags -join ', ')"
                        $CurrentDocument | Add-Member -MemberType NoteProperty -Name Tag -Value $Parsed.DocumentTags
                    }
                    continue
                }
                if($null -eq $CurrentDocument) {
                    Write-Debug "Yaml line $($k): Document Starting (implicit)"
                    # Implicit document start, Reset the current document
                    $Header = $true
                    $CurrentDocument = New-Object Object
                }
                if($Parsed.IsVersionDirective) {
                    Write-Debug "Yaml line $($k): YAML version directive: $($Parsed.VersionDirective)"
                    $CurrentDocument | Add-Member -MemberType NoteProperty -Name Version -Value $Parsed.VersionDirective
                    continue
                }
                if($Parsed.IsTagDirective) {
                    Write-Debug "Yaml line $($k): YAML tag declaration: $($Parsed.TagDirective | Foreach-Object { "{$($_.TagName) = $($_.TagValue)}" })"
                    $CurrentDocument | Add-Member -MemberType NoteProperty -Name TagDeclaration -Value $Parsed.TagDirective
                    continue
                }
                throw "Yaml line $($k): Unrecognized/unexpected directive found: ``$($YamlLines[$k])``"
                # continue
            }
            # Line is not a document level directive, leaving the Header
            if($Header -and -not ($Parsed.IsDocumentLevelLine)) {
                Write-Debug "Yaml line $($k): Document Body starting"
                # Leaving the document header
                $Header = $false
            }

            # Skip empty lines in the document body
            if($Parsed.Empty) {
                Write-Warning "Yaml line $($k): Empty line found"
                    <#
                    # TO DO: Verifiy if it is appropriate??
                    #>
                continue
            }

            # In the document body, mind the indentation and multiline strings!
            if($Parsed.IsMultiline -or $Parsed.IsMultilineByIndentation) {
                Write-Debug "Yaml line $($k): Multiline string detected"
                # Collect the multiline string
                $MultiLineString = [System.Collections.ArrayList]::new()
                $ParentIndentation = $Parsed.Indentation

                # Value could have started on the parent's line
                if($Parsed.IsFlowCollection -and $Parsed.FlowCollection.Value) {
                    Write-Debug "   > multiline Flow Collection with value in first line:`t``$($Parsed.FlowCollection.Value)``"
                    $MultiLineString.Add($Parsed.FlowCollection.Value) | Out-Null
                } elseif($Parsed.IsFlowScalar -and $Parsed.FlowScalar.Value) {
                    Write-Debug "   > multiline Flow Scalar with value in first line:`t``$($Parsed.FlowCollection.Value)``"
                    $MultiLineString.Add($Parsed.FlowCollection.Value) | Out-Null
                }
                
                if($k -lt $YamlLines.Length) {  # Multiline could start on the very last line of input, avoid out of range error
                    # Collect the indentation level of the children
                    $ChildIndentation = $YamlLines[$k + 1] | CountLeadingSpaces
                    # For Block Scalar, the indentation of the firstline may be overriden by declaration
                    if($Parsed.IsBlockScalar -and $null -ne $Parsed.BlockScalar.Indent) {
                        Write-Debug "   > multiline Block Scalar with extra Indentation:`t``$($Parsed.BlockScalar.Indent)``"
                        $ChildIndentation -= $Parsed.BlockScalar.Indent
                    }

                    # Capture the rest of the value
                    for($mlk = $k + 1; $mlk -lt $YamlLines.Length; $mlk ++) {
                        $mli = $YamlLines[$mlk] | CountLeadingSpaces
                        Write-Debug "Yaml line $($mlk): > analyzing string for multiline : Identation: $($mli), Content: ``$($YamlLines[$mlk])``"

                        # Value is always subject to indentation rules
                        if($mli -le $ParentIndentation) {
                            Write-Debug "   > multiline string ended by indentation: $($mli) <= $($ParentIndentation) (parent)"
                            # Indentation is less or equal the parent indentation => end of the multiline string
                            break;
                        }
                        if($mli -lt $ChildIndentation) {
                            Write-Debug "   > multiline string ended by indentation: $($mli) < $($ChildIndentation) (child)"
                            # Indentation is less than the child indentation => end of the multiline string
                            break;
                        }
                        # Value could be character delimited
                        if( ($Parsed.IsFlowCollection -and $Parsed.FlowCollection.MultiLineEnder -and $YamlLines[$mlk].EndsWith($Parsed.FlowCollection.MultiLineEnder)) `
                            -or ($Parsed.IsFlowScalar -and $Parsed.FlowScalar.MultiLineEnder -and $YamlLines[$mlk].EndsWith($Parsed.FlowScalar.MultiLineEnder)) 
                        ) {
                            Write-Debug "   > multiline string ended by delimiter"
                            # This is the end of the multiline string, strip the delimiter and return
                            $buf = $YamlLines[$mlk] <#.Substring($ChildIndentation)#>
                            $buf = $buf.Substring(0, $buf.Length - 1)
                            $MultiLineString.Add($buf) | Out-Null
                            break;
                        }
                        # None of the conditions met, continue to add the line to the multiline string
                        Write-Debug "   > multiline string continued: ``$($YamlLines[$mlk])``"
                        $MultiLineString.Add($YamlLines[$mlk] <#.Substring($ChildIndentation)#>) | Out-Null
                    }

                    # Move the cursor
                    Write-Warning "Moving cursor from $($k) to $($mlk)"
                    Write-Warning "   > BEFORE: ``$($YamlLines[$k])``"
                    Write-Warning "   > AFTER:  ``$($YamlLines[$mlk])``"
                    $k = $mlk
                }

                # We have our Multiline string in $MultiLineString, as an array.
                # Join the array according to the YAML rules
                $FoldedString = [System.Collections.ArrayList]::new()
                if($Parsed.IsFlowScalar) {
                    Write-Debug "Yaml line $($k): Multiline String was a FLOW SCALAR"
                    <#They can be on multiple lines, and can start on the same line as the parent node.
                    Linebreaks are subject to flow folding
                    Whitespace at the beginning or end of line are ignored
                    Whitespace inside a line are kept
                    If you add a blank line, it will not be folded
                    Every following empty line after the first will be kept as a newline
                    #>
                    $PrevTrimmed = $null
                    for($mlk = 0; $mlk -lt $MultiLineString.Count; $mlk ++) {
                        $Trimmed = $MultiLineString[$mlk].Trim()
                        if($Trimmed.Length -eq 0) {
                            if($null -ne $PrevTrimmed -and $PrevTrimmed.Length -eq 0) {
                                # This is a newline, following another newline, keep it as a newline
                                $FoldedString.Add('') | Out-Null
                            } else {
                                # A newline not following another newline, keep it as a space
                            }
                        } else {
                            # This is a segment of the string, preserve it
                            $FoldedString.Add($Trimmed) | Out-Null
                        }
                        $PrevTrimmed = $Trimmed
                    }
                    $FoldedString = $FoldedString -join ' '
                    
                    if($Parsed.FlowScalar.Type -eq "'") {
                        <# Single Quoted Scalars
                           Any character except ' will be returned literally.
                           The single quote itself is escaped by doubling it
                           Ref: https://www.yaml.info/learn/quote.html#single
                        #>
                        $FoldedString = $FoldedString.Replace("''","'")
                    } elseif($Parsed.FlowScalar.Type -eq '"') {
                        <# Double Quoted scalar
                           A double quoted scalar has the same rules as a single quoted scalar, plus escape sequences
                           The escaping rules are compatible to JSON
                           Escape characters are: \b, \f, \n, \r, \t, \\, \", \/, \xXX, \uXXXX, \UXXXXXXXX, \N, \_, \L, \P
                           Ref: https://www.yaml.info/learn/quote.html#double
                        #>
                        
                        $FoldedString = $FoldedString.Replace('\0',"`0")
                        $FoldedString = $FoldedString.Replace('\a',"`a")
                        $FoldedString = $FoldedString.Replace('\b',"`b")
                        $FoldedString = $FoldedString.Replace('\t',"`t")
                        $FoldedString = $FoldedString.Replace('\n',"`n")
                        $FoldedString = $FoldedString.Replace('\v',"`v")
                        $FoldedString = $FoldedString.Replace('\f',"`f")
                        $FoldedString = $FoldedString.Replace('\e',"`e")
                        $FoldedString = $FoldedString.Replace('\ '," ")
                        $FoldedString = $FoldedString.Replace('\/',"/")
                        $FoldedString = $FoldedString.Replace('\\',"\")
                        $FoldedString = $FoldedString.Replace('\N',"`u{85}")
                        $FoldedString = $FoldedString.Replace('\_',"`u{a0}")
                        $FoldedString = $FoldedString.Replace('\L',"`u{2028}")
                        $FoldedString = $FoldedString.Replace('\P',"`u{2029}")
                        # $FoldedString = $FoldedString.Replace('\x[0-90-f]{2}',"`u{$1}")   # Escaped 8 bit unicode character
                        # $FoldedString = $FoldedString.Replace('\u[0-90-f]{4}',"`u{$1}")   # Escaped 16 bit unicode character
                        # $FoldedString = $FoldedString.Replace('\U[0-90-f]{8}',"`u{$1}")   # Escaped 32 bit unicode character
                    }
                } elseif($Parsed.IsBlockScalar) {
                    Write-Debug "Yaml line $($k): Multiline String was a BLOCK SCALAR"
                    <# A Literal Block Scalar is introduced with the | pipe. The content starts on the next line and has to be indented:
                       The indendation is detected from the first (non-empty) line of the block scalar. And can be modified by the BlockScalarIndent
                        property (in the event where the first line is more indented than the following ones)

                       The Folded Block Scalar, will fold its lines with spaces. It is introduced with the > sign

                       Trailing spaces are kept
                       You can enforce a newline with an empty line
                       You can enforce newlines by increasing the indentation inside the block
                       If a line starting with # is indented correctly, it will not be interpreted as a comment

                       Block Scalars always end with a newline.
                       Chomping is used to remove the trailing newlines. It can be set to + (keep all), - (remove all) or nothing (keep one)
                    #>
                    if($Parsed.BlockScalar.Style -eq '>') {
                        Write-Debug "Yaml line $($k): Multiline String was a FOLDED BLOCK SCALAR"
                        # Folded Block Scalar
                        $PrevTrimmed = $null
                        for($mlk = 0; $mlk -lt $MultiLineString.Count; $mlk ++) {
                            if($mlk -ne 0 -and ($YamlLines[$mlk] | CountLeadingSpaces) -gt 0) {
                                # The line is more indented than the previous one, it goes on a new line, leading whitespace is preserved
                                $Trimmed = $MultiLineString[$mlk].TrimEnd()
                                $FoldedString.Add($Trimmed) | Out-Null
                                $PrevTrimmed = $Trimmed
                                continue
                            }
                            if($mlk -ne 0 -and ($YamlLines[$mlk - 1] | CountLeadingSpaces) -gt 0) {
                                # The previous line was more indented than this one, it goes on a new line
                                $Trimmed = $MultiLineString[$mlk].Trim()
                                $FoldedString.Add($Trimmed) | Out-Null
                                $PrevTrimmed = $Trimmed
                                continue
                            }
                            # Other cases
                            $Trimmed = $MultiLineString[$mlk].Trim()
                            if($Trimmed.Length -eq 0) {
                                if($null -ne $PrevTrimmed -and $PrevTrimmed.Length -eq 0) {
                                    # This is a newline, following another newline, keep it as a newline
                                    $FoldedString.Add('') | Out-Null
                                } else {
                                    # A newline not following another newline, keep it as a space
                                }
                            } else {
                                # This is a segment of the string, preserve it
                                $FoldedString.Add($Trimmed) | Out-Null
                            }
                            $PrevTrimmed = $Trimmed
                        }
                        $FoldedString = $FoldedString -join "`n"
                    } elseif($Parsed.BlockScalar.Style -eq '|') {
                        Write-Debug "Yaml line $($k): Multiline String was a LITERAL BLOCK SCALAR"
                        # Literal Block Scalar
                        
                        # The lines are preserved
                        for($mlk = 0; $mlk -lt $MultiLineString.Count; $mlk ++) {
                            $FoldedString.Add($MultiLineString[$mlk])
                        }
                        $FoldedString = $FoldedString -join "`n"
                    }

                    <# Chomp #>
                    switch($Parsed.BlockScalarChomp) {
                        '+' {
                            # Keep all trailing newlines
                            # Nothing to do
                        }
                        '-' {
                            # Remove all trailing newlines
                            $FoldedString = $FoldedString.TrimEnd("`n")
                        }
                        default {
                            # Keep one trailing newline
                            $FoldedString = $FoldedString.TrimEnd("`n")
                            $FoldedString = $FoldedString + "`n"
                        }
                    }
                } else {
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    #
                    #
                    # THERE IS ANOTHER OPTION HERE
                    # It could be that it is NOT a multiline string at all
                    # By example if Parsed was a Collection, it could be immediatelly followed by a child sequence:
                    #
                    #   trigger:
                    #   - {{ branch }}
                    #
                    # ==> The value of the key 'trigger' is therefore a block of yaml to be processed, and not a scalar!
                    #
                    #
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    Write-Warning "SEE HERE FOR WHAT TO DO: Line 822"
                    
                    Write-Debug "Yaml line $($k): Multiline String was a PLAIN SCALAR"
                    # Plain Scalar, multiline string
                    # The lines are preserved
                    for($mlk = 0; $mlk -lt $MultiLineString.Count; $mlk ++) {
                        $FoldedString.Add($MultiLineString[$mlk]) | Out-Null
                    }
                    $FoldedString = $FoldedString -join "`n"
                }
            }

            # The multiline string (if any) was captured and processed into $FoldedString
            if($null -ne $FoldedString) {
                Write-Debug "Yaml line $($k): Using the captured Multiline String as a value:`n$($FoldedString)"
                $Value = $FoldedString
            } else {
                Write-Debug "Yaml line $($k): Using the inline String as a value:`n$($Parsed.Value)"
                $Value = $Parsed.Value
            }

            # Proceed with structure and value processing
            if($null -ne $PrevParsed) {
                Write-Debug "Yaml line $($k): First item found, processing it"
                # This is the first item we process
                # Process Sequence, Mapping or Scalar
                if($Parsed.IsSequence) {
                    Write-Debug "Yaml line $($k): Item is a sequence"
                    $CurrentObject = [system.Collections.ArrayList]::new()
                    $CurrentObject.Add($Value)
                } elseif($Parsed.IsMapping) {
                    Write-Debug "Yaml line $($k): Item is a mapping"
                    $CurrentObject = @{}
                    $CurrentObject.Add($Parsed.Key.Value, $Value)
                } else {
                    Write-Debug "Yaml line $($k): Item is a scalar"
                    $CurrentObject = $Value
                }
                $PrevParsed = $Parsed
            } else {
                # This is another object, it can be sibling, parent or child
                if($Parsed.Indentation -eq $PrevParsed.Indentation) {
                    Write-Debug "Yaml line $($k): Sibling item found, processing it"
                    # This is a sibling item
                    # Process Sequence, Mapping or Scalar
                    if($Parsed.IsSequence) {
                        Write-Debug "Yaml line $($k): Item is a sequence"
                        $CurrentObject.Add($Value)
                    } elseif($Parsed.IsMapping) {
                        Write-Debug "Yaml line $($k): Item is a mapping"
                        $CurrentObject.Add($Parsed.Key.Value, $Value)
                    } else {
                        Write-Warning "Yaml line $($k): Item is a scalar - This is unexpected for a sibling!"
                        throw "Yaml line $($k): Invalid Yaml Line: $Line - Expected a Sequence or Mapping"
                    }
                    $PrevParsed = $Parsed
                } elseif($Parsed.Indentation -gt $PrevParsed.Indentation) {
                    Write-Debug "Yaml line $($k): Child item found, processing it"
                    # This is a child item
                    
                    # Collect the lines of the child, by their identation
                    $ChildLines = [System.Collections.ArrayList]::new()
                    for($mlk = $k; $mlk -lt $YamlLines.Length; $mlk ++) {
                        $mli = $YamlLines[$mlk] | CountLeadingSpaces
                        if($mli -le $Parsed.Indentation) {
                            # End of the child item
                            break;
                        } else {
                            $ChildLines.Add($YamlLines[$mlk]) | Out-Null
                        }
                    }
                    Write-Debug "Yaml line $($k): Calling recursively to process the child item"
                    $ChildObject = ProcessAllLines -YamlLines $ChildLines -Identation $mli

                    Write-Debug "Yaml line $($k): Child item processed, moving cursor from $($k) to $($mlk)"
                    Write-Warning "BEFORE: $($YamlLines[$k])"
                    Write-Warning "AFTER:  $($YamlLines[$mlk])"
                    $k = $mlk

                    # Process Sequence, Mapping or Scalar
                    if($Parsed.IsSequence) {
                        Write-Debug "Yaml line $($k): Item is a sequence"
                        $CurrentObject.Add($ChildObject)
                    } elseif($Parsed.IsMapping) {
                        Write-Debug "Yaml line $($k): Item is a mapping"
                        $CurrentObject.Add($Parsed.Key.Value, $ChildObject)
                    } else {
                        Write-Warning "Yaml line $($k): Item is a scalar - This is unexpected for a child!"
                        throw "Yaml line $($k): Invalid Yaml Line: $Line - Expected a Sequence or Mapping"
                    }

                } elseif($Parsed.Indentation -lt $PrevParsed.Indentation) {
                    Write-Debug "Yaml line $($k): Parent item found, stop processing and return the object"
                    Write-Warning "Yaml line $($k): Parent item found - This is unexpected - save maybe for the first level!"
                    # This is a parent item
                    # Return the object to the caller
                    return $CurrentObject
                }
            }
        }

        # IT WAS USELESS TO CAPTURE THE YAML version and YAML tag directives, as we do nto use them
        # $CurrentDocument | Add-Member -MemberType NoteProperty -Name Body -Value $CurrentObject
        #
        # Return the Object right away
        return $CurrentObject
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
$yml | ProcessLine | Select-Object Line,Indentation,Depth,Key,Cast,QuotedFlowScalarValue,MultilineQuotedFlowScalarValue,Multiline,BlockScalarStyle,BlockScalarChomp,BlockScalarIndent,MultilineQuotedFlowScalarType | Format-Table

$AllInes = Get-Content z:\t.yaml
ProcessAllLines -YamlLines $AllInes -Identation 0 -Debug