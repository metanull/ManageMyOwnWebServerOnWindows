<#
    .SYNOPSIS
    Writes a development message with appropriate icon and color

    .DESCRIPTION
    Displays a message for development utilities with icon and color based on type

    .PARAMETER Message
    The message to display

    .PARAMETER Type
    The type of message (Info, Error, Success, Warning, Step, Header). Default is Info.

    .EXAMPLE
    Write-Development -Message "Server started successfully!" -Type Success

    .EXAMPLE
    Write-Development -Message "An error occurred while starting the server." -Type Error

    .EXAMPLE
    Write-Development -Message "This is an information message."
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Write-Host is appropriate for colored user output in development utilities')]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [AllowNull()]
    [AllowEmptyString()]
    [string]$Message,

    [ValidateSet('Info','Error','Success','Warning','Step','Header')]
    [string]$Type = 'Info'
)

Process {
    switch ($Type) {
        'Error'   { $icon = Get-ModuleIcon 'Error';       $color = $script:ModuleColorError }
        'Success' { $icon = Get-ModuleIcon 'CheckMark';   $color = $script:ModuleColorSuccess }
        'Warning' { $icon = Get-ModuleIcon 'Warning';     $color = $script:ModuleColorWarning }
        'Step'    { $icon = Get-ModuleIcon 'Rocket';      $color = $script:ModuleColorStep }
        'Header'  { $icon = Get-ModuleIcon 'Celebration'; $color = $script:ModuleColorHeader }
        default   { $icon = Get-ModuleIcon 'Info';        $color = $script:ModuleColorInfo }
    }

    if($Type -in @('Header')) {
        Write-Host ""
        Write-Host "$icon $Message" -ForegroundColor $color
        Write-Host ""
    } else {
        Write-Host "$icon $Message" -ForegroundColor $color
    }
    
}