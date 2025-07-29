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
        Rocket = "`u1F680"         # 🚀
        CheckMark = "`u2705"       # ✅
        Warning = "`u26A0"         # ⚠️
        Info = "`u2139"            # ℹ️
        Error = "`u274C"           # ❌

        # Application Icons
        Celebration = "`u1F389"    # 🎉
        MobilePhone = "`u1F4F1"    # 📱
        Satellite = "`u1F4E1"      # 📡
        Lightning = "`u26A1"       # ⚡

        # Tool Icons
        Wrench = "`u1F527"         # 🔧
        Books = "`u1F4DA"          # 📚
        GreenHeart = "`u1F49A"     # 💚
        Key = "`u1F511"            # 🔑
        FloppyDisk = "`u1F4BE"     # 💾

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
Set-Variable -Name "ModuleColorHeader" -Value "White" -Option Constant
