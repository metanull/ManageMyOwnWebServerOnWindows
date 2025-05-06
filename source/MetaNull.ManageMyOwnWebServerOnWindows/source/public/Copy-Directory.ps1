<#
    .SYNOPSIS
        Copies the contents of a source directory to a target directory, preserving the directory structure and symbolic links.
    .OUTPUTS
        The target directory after copying the contents.
    .DESCRIPTION
        Copies the contents of a source directory to a target directory, preserving the directory structure and symbolic links.
    .PARAMETER Source
        The source directory to copy from.
    .PARAMETER Target
        The target directory to copy to.
    .PARAMETER AsChildren
        If specified, the function will copy the contents of the source directory as children of the target directory.
    .EXAMPLE
        # Copies the contents of "C:\Source" to "C:\Target", preserving the directory structure and symbolic links.
        Copy-Directory -Source "C:\Source" -Target "C:\Target"
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateScript({ Get-ChildItem $_ | Test-Path -PathType Container })]
    [SupportsWildcards()]
    [string]
    $Source,

    [Parameter(Mandatory, Position = 1)]
    [ValidateScript({ (-not (Test-Path $_)) -or (Test-Path $_ -PathType Container) })]
    [string]
    $Target,

    [switch]$AsChildren
)
Process {
    Get-Item -Path $Source | ForEach-Object {
        $InnerSource = $_.FullName # Get the full path of the source directory

        if (-Not (Test-Path $InnerSource -PathType Container)) {
            # If the source path is not a directory, skip it
            return
        }
        $InnerSource = Resolve-Path $InnerSource | Select-Object -ExpandProperty Path

        # Compute the target directory based on the AsChildren parameter
        if( $AsChildren.IsPresent -and $AsChildren ) {
            # If AsChildren is specified, set the target to the specified target directory with the source directory name appended
            $InnerTarget = Join-Path -Path $Target -ChildPath (Split-Path -Path $InnerSource -Leaf)
        } else {
            # If AsChildren is not specified, set the target to the specified target directory
            $InnerTarget = $Target
        }

        # Check if the target directory exists, if not create it
        if (-Not (Test-Path $InnerTarget)) {
            New-Item -ItemType Directory -Path $InnerTarget | Out-Null
        }
        
        # Get the full path of the target directory
        $InnerTarget = Resolve-Path $InnerTarget | Select-Object -ExpandProperty Path

        # Copy the contents of the source directory to the target directory
        Get-ChildItem -Path $InnerSource -Recurse | ForEach-Object {
            $targetPath = Join-Path -Path $InnerTarget -ChildPath $_.FullName.Substring($InnerSource.Length)
            $targetDir = Split-Path -Path $targetPath -Parent
            if (-Not (Test-Path $targetDir)) {
                # Create the parent directory if it doesn't exist
                Write-Verbose "Creating parent directory for file: $targetDir"
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }
            if (Test-Path $targetPath) {
                # If the target path exists and is a file, remove it
                if (-not $_.PSIsContainer) {
                    Write-Verbose "Removing existing file: $targetPath"
                    Remove-Item -Path $targetPath
                }
            } else {
                # If the target path does not exist, and it should be a directory, create it
                if ($_.PSIsContainer) {
                    # Create the directory in the target directory
                    Write-Verbose "Creating directory: $targetPath"
                    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                }
            }
            if ($_.LinkType -eq "SymbolicLink") {
                # Fetch the Link's target as an absolute path
                try {
                    $linkTarget = Join-Path -Resolve -Path (Split-Path $_.FullName -Parent) -ChildPath ((Get-Item $_.FullName).Target | Select-Object -First 1) -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to resolve symbolic link target: $(((Get-Item $_.FullName).Target | Select-Object -First 1))"
                    return
                }
                
                # Copy the symbolic link
                Write-Verbose "Creating symbolic link: $targetPath -> $linkTarget"
                New-Item -ItemType SymbolicLink -Path $targetPath -Target $linkTarget -Force | Out-Null
            }
            else {
                # Copy the file to the target directory
                Write-Verbose "Copying file: $($_.FullName) to $targetPath"
                Copy-Item -Path $_.FullName -Destination $targetPath
            }
        }
        Get-Item $InnerTarget
    }
}