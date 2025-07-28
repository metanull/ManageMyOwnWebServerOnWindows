# Module Constants and Initialization

# Icon configuration based on PowerShell version
$script:ModuleIcons = @{}
$script:UseEmojis = $false

# Detect PowerShell version and set icon preference
if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PowerShell 7+ supports Unicode emojis better
    $script:UseEmojis = $true
    $script:ModuleIcons = @{
        # Status Icons
        Rocket = "🚀"
        CheckMark = "✅"
        Warning = "⚠️"
        Info = "ℹ️"
        Error = "❌"

        # Application Icons
        Celebration = "🎉"
        MobilePhone = "📱"
        Satellite = "📡"
        Lightning = "⚡"

        # Tool Icons
        Wrench = "🔧"
        Books = "📚"
        GreenHeart = "💚"
        Key = "🔑"
        FloppyDisk = "💾"

        # Fallback plain text versions
        PlainText = @{
            Rocket = "[START]"
            CheckMark = "[OK]"
            Warning = "[WARN]"
            Info = "[INFO]"
            Error = "[ERROR]"
            Celebration = "[SUCCESS]"
            MobilePhone = "[APP]"
            Satellite = "[API]"
            Lightning = "[HMR]"
            Wrench = "[TOOLS]"
            Books = "[DOCS]"
            GreenHeart = "[HEALTH]"
            Key = "[DASH]"
            FloppyDisk = "[DEV]"
        }
    }
} else {
    # PowerShell 5.1 and earlier - use plain text icons
    $script:UseEmojis = $false
    $script:ModuleIcons = @{
        PlainText = @{
            Rocket = "[START]"
            CheckMark = "[OK]"
            Warning = "[WARN]"
            Info = "[INFO]"
            Error = "[ERROR]"
            Celebration = "[SUCCESS]"
            MobilePhone = "[APP]"
            Satellite = "[API]"
            Lightning = "[HMR]"
            Wrench = "[TOOLS]"
            Books = "[DOCS]"
            GreenHeart = "[HEALTH]"
            Key = "[DASH]"
            FloppyDisk = "[DEV]"
        }
    }
}

# Color constants for consistent output
Set-Variable -Name "ModuleColorSuccess" -Value "Green" -Option Constant
Set-Variable -Name "ModuleColorWarning" -Value "Yellow" -Option Constant
Set-Variable -Name "ModuleColorError" -Value "Red" -Option Constant
Set-Variable -Name "ModuleColorInfo" -Value "Cyan" -Option Constant
Set-Variable -Name "ModuleColorStep" -Value "Magenta" -Option Constant
