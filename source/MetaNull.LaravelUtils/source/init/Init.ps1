# Module Constants and Initialization
$script:ModuleIcons = @{
    Unicode = @{
        # Unicode Emojis for PowerShell 7.0 and later
        Rocket = "`u{1F680}"         # 🚀
        CheckMark = "`u{2705}"       # ✅
        Warning = "`u{26A0}"         # ⚠️
        Info = "`u{2139}"            # ℹ️
        Error = "`u{274C}"           # ❌

        Celebration = "`u{1F389}"    # 🎉
        MobilePhone = "`u{1F4F1}"    # 📱
        Satellite = "`u{1F4E1}"      # 📡
        Lightning = "`u{26A1}"       # ⚡

        Wrench = "`u{1F527}"         # 🔧
        Books = "`u{1F4DA}"          # 📚
        GreenHeart = "`u{1F49A}"     # 💚
        Key = "`u{1F511}"            # 🔑
        FloppyDisk = "`u{1F4BE}"     # 💾
    }
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

# Use emojis based on PowerShell version
if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.PSVersion.Major -ge 7) {
    $script:UseEmojis = $true
} elseif ($PSVersionTable.PSEdition -eq 'Desktop' -and $PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 1) {
    $script:UseEmojis = $true
} else {
    $script:UseEmojis = $false
}

# Color constants for consistent output
Set-Variable -Name "ModuleColorSuccess" -Value "Green" -Option Constant
Set-Variable -Name "ModuleColorWarning" -Value "Yellow" -Option Constant
Set-Variable -Name "ModuleColorError" -Value "Red" -Option Constant
Set-Variable -Name "ModuleColorInfo" -Value "Cyan" -Option Constant
Set-Variable -Name "ModuleColorStep" -Value "Magenta" -Option Constant
Set-Variable -Name "ModuleColorHeader" -Value "White" -Option Constant

Set-Variable -Name "ModuleLaravelLogFile" -Value 'storage/logs/laravel.log' -Option Constant
