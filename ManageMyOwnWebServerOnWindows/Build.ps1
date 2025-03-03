[CmdletBinding()]
param(
    [switch] $IncrementMajor,
    [switch] $IncrementMinor,
    [switch] $IncrementRevision
)
Begin {
    # 1. Load the Build Settings
	$Build = Import-PowerShellDataFile -Path (Join-Path -Path $PSScriptRoot -ChildPath '.\Build.psd1' -Resolve -ErrorAction 'Stop')

    # 2. Populate build settings with calculated values
    $Build.CurrentYMD = Get-Date -Format 'yyyy.MM.dd'

    # 2.1 Create the destination directory (where the module code is placed)
    if(-not (Test-Path -Path $Build.Destination)) {
        New-Item -Path $Build.Destination -ItemType Container -ErrorAction Stop | Out-null
    }

    # 2.2 Resolve source and destination root directories (get their fully qualified path)
    $Build.Destination = Join-Path -Path $PSScriptRoot -ChildPath $Build.Destination
    $Build.Source = Join-Path -Path $PSScriptRoot -ChildPath $Build.Source -Resolve -ErrorAction Stop

    # 2.3 Add directory structure if required
    @('init','tools','class','public','private') | Foreach-Object {
        if(-not (Test-Path (Join-Path -Path $Build.Source -ChildPath $_) )) {
            New-Item -Path $Build.Source -Name $_ -ItemType Directory -ErrorAction Stop | Out-Null
        }
    }

    # 2.4 Load and manage the build number
    $Build.VersionPath = Join-Path -Path $PSScriptRoot -ChildPath "Version.psd1"
    if(-not (Test-Path -Path $Build.VersionPath)) {
        $Item = New-Item -Path $Build.VersionPath -ItemType File -ErrorAction Stop | Out-Null
        '@{Major=0;Minor=0;Build=0;Revision=0}' | Set-Content $Item
    }

    $Version = Import-PowerShellDataFile -Path $Build.VersionPath
    if($IncrementMajor) {
        $Version.Major ++
        $Version.Minor = 0
        $Version.Revision = 0
    }
    elseif($IncrementMinor) {
        $Version.Minor ++
        $Version.Revision = 0
    }
    elseif($IncrementRevision) {
        $Version.Revision ++
    }
    $Version.Build ++
    $Build.Version = [version]::new("$($Version.Major).$($Version.Minor).$($Version.Build).$($Version.Revision)")

    # 2.5 Create the versionned desitnation directory
    $Destination = Join-Path $Build.Destination $Build.Version
    if((Test-Path -Path $Destination)) {
        Write-Warning 'Destination exists!'
        Remove-Item -Force -Path $Destination -Confirm -ErrorAction Stop
    }
    New-Item -Path $Destination -ItemType Container -ErrorAction Stop | Out-null
    $Build.Destination = Resolve-Path -Path $Destination

    # 2.5.2 Create the tools subdirectory in the module
    New-Item -Path (Join-Path $Destination 'tools') -ItemType Container -ErrorAction Stop | Out-null

    # 2.6 Calculate the fully qualified path of the Module's code file
    $Build.ManifestPath = Join-Path -Path $Build.Destination -ChildPath "$($Build.Name).psd1"
    New-Item -Path $Build.ManifestPath -ItemType File -ErrorAction Stop | Out-null

    # 2.7 Calculate the fully qualified path of the Module's manifest
    $Build.ModulePath = Join-Path -Path $Build.Destination -ChildPath "$($Build.Name).psm1"
    New-Item -Path $Build.ModulePath -ItemType File -ErrorAction Stop | Out-null

    # 2.8 Calculate the fully qualified path of the Module's init script file (this script will be executed, in the client's scope while module is getting loaded)
    $Build.InitScriptPath = Join-Path -Path $Build.Destination -ChildPath "tools\init.ps1"
    New-Item -Path $Build.InitScriptPath -ItemType File -ErrorAction Stop | Out-null

    # 2.9 Calculate the fully qualified path of the Module's class script file (there are some limitation for classes exposed in this way, see https://stackoverflow.com/questions/31051103/how-to-export-a-class-in-a-powershell-v5-module)
    $Build.ClassScriptPath = Join-Path -Path $Build.Destination -ChildPath "tools\classes.ps1"
    New-Item -Path $Build.ClassScriptPath -ItemType File -ErrorAction Stop | Out-null

}
End {
    # Increment the build number, and save
    Clear-Content -Path $Build.VersionPath
    '@{' | Set-Content -Path $Build.VersionPath
    "  Major = $($Build.Version.Major)" | Add-Content -Path $Build.VersionPath
    "  Minor = $($Build.Version.Minor)" | Add-Content -Path $Build.VersionPath
    "  Revision = $($Build.Version.Revision)" | Add-Content -Path $Build.VersionPath
    "  Build = $($Build.Version.Build)" | Add-Content -Path $Build.VersionPath
    '}' | Add-Content -Path $Build.VersionPath
}
Process {
    # Stores the list of public functions exposed by the module
    $FunctionsToExport = @()

    # Stores the list of TypeData (for module's classes) exposed by the module
    $TypesToExport = @()

    # Stores the list of FormatData (for module's classes) exposed by the module
    $FormatsToExport = @()

    # Load dependencies INTO THE BUILD process, if required
    $Build.AssemblyDependencies | ForEach-Object {
        $AssemblyName = $_ -replace '\.[^\.]+$'
        $ImportScript = @"
if (-not ("$($_)" -as [Type])) {
    Add-Type -Assembly $($AssemblyName)
}

"@
        $ImportScript | Add-Content -Path $Build.InitScriptPath
    }

    # Register module dependencies
    $Build.ModuleDependencies | ForEach-Object {
        "#Requires -Module $($_)" | Add-Content -Path $Build.ModulePath

        # Add the constraint also to the init script
        "#Requires -Module $($_)" | Add-Content -Path $Build.InitScriptPath
    }

    # 1. Build the Module's code file
    # 1.0 Copy the README file
    Get-ChildItem -Path $Build.Source -File -Filter '*.md' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.md' ) {
            $_ | Copy-Item -Destination $Build.Destination
        }
    }

    # 1.1 Add code on top of the module, before any Function definition
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'init') -File -Filter '*.ps1' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1' ) {
            Get-Content -Path $_.FullName | Add-Content -Path $Build.ModulePath
        }
    }
    # 1.2 Add private functions (not exposed by the module)
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'private') -File -Filter '*.ps1' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1' ) {
            $FunctionName  = $_.Name -replace '\.ps1$'
            "Function $($FunctionName) {" | Add-Content -Path $Build.ModulePath
            Get-Content -Path $_.FullName | Add-Content -Path $Build.ModulePath
            '}' | Add-Content -Path $Build.ModulePath
        }
    }
    # 1.3 Add public functions (exposed by the module)
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'public') -File -Filter '*.ps1' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1' ) {
            $FunctionName  = $_.Name -replace '\.ps1$'
            "Function $($FunctionName) {" | Add-Content -Path $Build.ModulePath
            Get-Content -Path $_.FullName | Add-Content -Path $Build.ModulePath
            '}' | Add-Content -Path $Build.ModulePath
            $FunctionsToExport += $FunctionName
        }
    }
    # 1.4 Add class definitions
    # 1.4.a Add class' code to the module's class file
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'class') -File -Filter '*.ps1' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1' ) {
            Get-Content -Path $_.FullName | Add-Content -Path $Build.ClassScriptPath
        }
    }
    # # 1.4.b Add Init code to make the class modules available to the calling process when they use Import-Module
    # if( Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'class') -File -Filter '*.ps1' | Where-Object {[System.IO.Path]::GetExtension($_) -eq '.ps1' }) {
    #     # "# using module $($Build.ModulePath)" | Add-Content -Path $Build.InitScriptPath
    #     "# using module $($Build.Name)" | Add-Content -Path $Build.InitScriptPath
    # }

    # 1.4.b Copy "TypesData" file to the module's root directory
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'class') -File -Filter '*.types.ps1xml' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1xml' ) {
            $TypesToExport += $_.Name
            $_ | Copy-Item -Destination $Build.Destination
        }
    }
    # 1.4.b Copy "FormatData" file to the module's root directory
    Get-ChildItem -Path (Join-Path -Path $Build.Source -ChildPath 'class') -File -Filter '*.formats.ps1xml' | Foreach-Object {
        if([System.IO.Path]::GetExtension($_) -eq '.ps1xml' ) {
            $FormatsToExport += $_.Name
            $_ | Copy-Item -Destination $Build.Destination
        }
    }

    # 2. Build the Module's manifest
    $ModuleManifest = $Build.ModuleSettings.Clone()
    $ModuleManifest.RootModule = "$($Build.Name).psm1"
    $ModuleManifest.ModuleVersion = $Build.Version
    $ModuleManifest.FunctionsToExport = $FunctionsToExport
    $ModuleManifest.ScriptsToProcess = @(
        "$($Build.InitScriptPath | Split-Path -Parent | Split-Path -Leaf)\$($Build.InitScriptPath | Split-Path -Leaf)"
        "$($Build.ClassScriptPath | Split-Path -Parent | Split-Path -Leaf)\$($Build.ClassScriptPath | Split-Path -Leaf)"
    )
    if($TypesToExport.Length) {
        $ModuleManifest.TypesToProcess = $TypesToExport
    }
    if($FormatsToExport.Length) {
        $ModuleManifest.FormatsToProcess = $FormatsToExport
    }
    # Add the requirement to the Manifest
    $ModuleManifest.RequiredModules = $Build.ModuleDependencies

    New-ModuleManifest @ModuleManifest -Path $Build.ManifestPath -ErrorAction Stop
    Get-Item ($Build.ManifestPath | Split-Path)
}