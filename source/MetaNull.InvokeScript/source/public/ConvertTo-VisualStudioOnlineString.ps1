<#
.SYNOPSIS
    Write a string in the Visual Studio Online format

.DESCRIPTION
    Write a string in the Visual Studio Online format

.PARAMETER Message
    The message to write

.PARAMETER Format
    The format of the message
    'group', 'endgroup', 'section', 'warning', 'error', 'debug', 'command'

.PARAMETER CompleteTask
    Complete the task
    'Succeeded', 'SucceededWithIssues', 'Failed'

.PARAMETER SetTaskVariable
    Set a task variable

.PARAMETER SetTaskSecret
    Set a task secret

.PARAMETER PrependTaskPath
    Prepend a path to the task

.PARAMETER UploadTaskFile
    Upload a file to the task

.PARAMETER SetTaskProgress
    Set the task progress

.PARAMETER LogIssue
    Log an issue
    'warning', 'error'

.PARAMETER AddBuildTag
    Add a build tag

.PARAMETER Name
    The name of the variable

.PARAMETER IsSecret
    Is the variable a secret

.PARAMETER IsReadOnly
    Is the variable read-only

.PARAMETER IsOutput
    Is the variable an output

.PARAMETER Value
    The value of the variable

.PARAMETER Path
    The path to prepend or upload

.PARAMETER Progress
    The progress value

.PARAMETER Type
    The type of issue

.PARAMETER SourcePath
    The source path of the issue

.PARAMETER LineNumber
    The line number of the issue

.PARAMETER ColNumber
    The column number of the issue

.PARAMETER Code
    The code of the issue

.PARAMETER Tag
    The tag to add to the build

.EXAMPLE
    # Write a message
    'Task completed successfully' | ConvertTo-VisualStudioOnlineString -Format 'section'

.EXAMPLE
    # Complete a task
    ConvertTo-VisualStudioOnlineString -CompleteTask -Result 'Succeeded' -Message 'Task completed successfully'

.EXAMPLE
    # Set a task variable
    ConvertTo-VisualStudioOnlineString -SetTaskVariable -Name 'VariableName' -Value 'VariableValue'

.EXAMPLE
    # Set a task secret
    ConvertTo-VisualStudioOnlineString -SetTaskSecret -Value 'SecretValue'

.EXAMPLE
    # Prepend a path to the task
    ConvertTo-VisualStudioOnlineString -PrependTaskPath -Path 'C:\Path\To\Prepend'

.EXAMPLE
    # Upload a file to the task
    ConvertTo-VisualStudioOnlineString -UploadTaskFile -Path 'C:\Path\To\Upload'

.EXAMPLE
    # Set the task progress
    ConvertTo-VisualStudioOnlineString -SetTaskProgress -Progress 50 -Message 'Task is 50% complete'

.EXAMPLE
    # Log an issue
    ConvertTo-VisualStudioOnlineString -LogIssue -Type 'warning' -Message 'This is a warning'

.EXAMPLE
    # Add a build tag
    ConvertTo-VisualStudioOnlineString -AddBuildTag -Tag 'tag'

.OUTPUTS
    System.String

.LINK
    https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/logging-commands?view=azure-devops&tabs=powershell
#>
[CmdletBinding(DefaultParameterSetName='Format')]
[OutputType([string])]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Parameters are used to define the script''s ParameterSet.')]
param(
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Format')]
    [Parameter(Mandatory = $false, ValueFromPipeline, ParameterSetName='Command-TaskComplete')]
    [Parameter(Mandatory = $false, ValueFromPipeline, ParameterSetName='Command-TaskSetProgress')]
    [Parameter(Mandatory = $false, ValueFromPipeline, ParameterSetName='Command-TaskLogIssue')]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $Message,

    [Parameter(Mandatory = $false, ParameterSetName='Format')]
    [ValidateSet('group', 'endgroup', 'section', 'warning', 'error', 'debug', 'command')]
    [string] $Format,


    [Parameter(Mandatory, ParameterSetName='Command-TaskComplete')]
    [switch] $CompleteTask,

    [Parameter(Mandatory, ParameterSetName='Command-TaskSetVariable')]
    [switch] $SetTaskVariable,

    [Parameter(Mandatory, ParameterSetName='Command-TaskSetSecret')]
    [switch] $SetTaskSecret,

    [Parameter(Mandatory, ParameterSetName='Command-TaskPrependPath')]
    [switch] $PrependTaskPath,

    [Parameter(Mandatory, ParameterSetName='Command-TaskUploadFile')]
    [switch] $UploadTaskFile,

    [Parameter(Mandatory, ParameterSetName='Command-TaskSetProgress')]
    [switch] $SetTaskProgress,

    [Parameter(Mandatory, ParameterSetName='Command-TaskLogIssue')]
    [switch] $LogIssue,

    [Parameter(Mandatory, ParameterSetName='Command-BuildAddBuildTag')]
    [switch] $AddBuildTag,


    [Parameter(Mandatory, ParameterSetName='Command-TaskComplete')]
    [ValidateSet('Succeeded', 'SucceededWithIssues', 'Failed')]
    [string] $Result,


    [Parameter(Mandatory, ParameterSetName='Command-TaskSetVariable')]
    [string] $Name,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskSetVariable')]
    [switch] $IsSecret,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskSetVariable')]
    [switch] $IsReadOnly,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskSetVariable')]
    [switch] $IsOutput,

    [Parameter(Mandatory = $false, ValueFromPipeline, ParameterSetName='Command-TaskSetVariable')]
    [Parameter(Mandatory = $false, ValueFromPipeline, ParameterSetName='Command-TaskSetSecret')]
    [AllowEmptyString()]
    [AllowNull()]
    [string] $Value,

    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Command-TaskPrependPath')]
    [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Command-TaskUploadFile')]
    [string] $Path,

    [Parameter(Mandatory, ParameterSetName='Command-TaskSetProgress')]
    [ValidateRange(0, 100)]
    [int] $Progress,

    [Parameter(Mandatory, ParameterSetName='Command-TaskLogIssue')]
    [ValidateSet('warning', 'error')]
    [string] $Type,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskLogIssue')]
    [string] $SourcePath,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskLogIssue')]
    [int] $LineNumber,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskLogIssue')]
    [int] $ColNumber,

    [Parameter(Mandatory = $false, ParameterSetName='Command-TaskLogIssue')]
    [int] $Code,

    [Parameter(Mandatory, ParameterSetName='Command-BuildAddBuildTag')]
    [ValidateScript({ $_ -match '^[a-z][\w\.\-]+$' })]
    [string] $Tag
)
Process {
    switch($PSCmdlet.ParameterSetName) {
        'Format' {
            return "##[$Format]$Message"
        }
        'Command-TaskComplete' {
            return "##vso[task.complete result=$Result]$Message"
        }
        'Command-TaskSetVariable' {
            $IsSecretString = "$("$($IsSecret.IsPresent -and $IsSecret)".ToLower())"
            $IsOutputString = "$("$($IsOutput.IsPresent -and $IsOutput)".ToLower())"
            $IsReadOnlyString = "$("$($IsReadOnly.IsPresent -and $IsReadOnly)".ToLower())"
            return "##vso[task.setvariable variable=$Name;isSecret=$IsSecretString;isOutput=$IsOutputString;isReadOnly=$IsReadOnlyString]$Value"
        }
        'Command-TaskSetSecret' {
            return "##vso[task.setsecret]$Value"
        }
        'Command-TaskPrependPath' {
            return "##vso[task.prependpath]$Path"
        }
        'Command-TaskUploadFile' {
            return "##vso[task.uploadfile]$Path"
        }
        'Command-TaskSetProgress' {
            return "##vso[task.setprogress value=$Progress;]$Message"
        }
        'Command-TaskLogIssue' {
            $Properties = @()
            if ($SourcePath) { $Properties += "sourcepath=$SourcePath" }
            if ($LineNumber) { $Properties += "linenumber=$LineNumber" }
            if ($ColNumber) { $Properties += "colnumber=$ColNumber" }
            if ($Code) { $Properties += "code=$Code" }
            return "##vso[task.logissue type=$Type;$($Properties -join ';')]$Message"
        }
        'Command-BuildAddBuildTag' {
            return "##vso[build.addbuildtag]$Tag"
        }
    }
    return
}