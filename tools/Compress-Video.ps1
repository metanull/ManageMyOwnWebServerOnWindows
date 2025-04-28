function Compress-Video {
	<#
        .NOTES
            Author: Pascal Havelange
        .SYNOPSIS
            Encode a video file using HEVC/x.265 + downscale
        .DESCRIPTION
            Encode a video file using HEVC/x.265 + downscale to a desired resolution (if any larger).
            Preseve the original Last Modification date
            Copy the original metadata (or add a creation_time & location metadata if it can be detected)
        .PARAMETER Item
            The input file to compress
        .PARAMETER Force
            If set, overwrite output file when it exists
        .PARAMETER Test
            If set, only process the first 3 seconds of video
        .PARAMETER NoMetaData
            If set, original metadata is not copied, but a Location metadata is added (if it can be detected)
        .PARAMETER Fast
            If set, use a fast encoding preset (target file will be slightly bigger, but the overall operation will be faster)
        .PARAMETER Width
            Set the target downscaling Width
        .PARAMETER Height
            Set the target downscaling Height
        .PARAMETER HD
            Downscale to HD (1280x720)
        .PARAMETER FullHD
            Downscale to FullHD (1920x1080)
        .PARAMETER 2K
            Downscale to 2K (2048x1080)
        .PARAMETER 4K
            Downscale to 4K (3840x2160)
        .PARAMETER 8K
            Downscale to 8K (7680x4320)
        .PARAMETER 10K
            Downscale to 10K (10240x4320)
        .EXAMPLE
            # Compress a single video
            Compress-Video -Item C:\MyVideo.MOV
        .EXAMPLE
            # Compress a single video, downscale to HD
            Get-Item C:\MyVideo.MOV | Compress-Video -HD
        .EXAMPLE
            # Compress all videos in a folder, downscale to 640x480
            Get-ChildItem -Recurse C:\Videos | Compress-Video -Width 640 -Height 480
	#>
	[CmdLetBinding(SupportsShouldProcess, ConfirmImpact = 'Low', DefaultParameterSetName = 'NoScale')]
	param(
		[Parameter(ValueFromPipeline, Mandatory, Position = 0)]
		[ValidateScript({ $_ | Test-Path -PathType Leaf })]
		[System.IO.FileInfo]
		$Item,

		[Parameter(Mandatory, ParameterSetName = 'Scale')]
		[int]$With,
		[Parameter(Mandatory, ParameterSetName = 'Scale')]
		[int]$Height,

		[Parameter(Mandatory, ParameterSetName = 'HD')]
		[switch] $HD,

		[Parameter(Mandatory, ParameterSetName = 'FHD')]
		[switch] $FullHD,

		[Parameter(Mandatory, ParameterSetName = '2K')]
		[switch] $2K,

		[Parameter(Mandatory, ParameterSetName = '4K')]
		[switch] $4K,

		[Parameter(Mandatory, ParameterSetName = '8K')]
		[switch] $8k,

		[Parameter(Mandatory, ParameterSetName = '10K')]
		[switch] $10k,

		[switch] $Force,
		[switch] $Test,
		[switch] $NoMetaData,
		[switch] $Fast
	)
	Process {
		$InPath = $Item.FullName
		$OutPath = $Item.FullName -replace '\.([a-z][a-z0-9]+)$', '-compressed.mp4'
		Write-Debug "Source: $InPath"
		Write-Debug "Destination: $OutPath"

		# When a custom scale is selected, add it to the Resolutions array
		if ($PSCmdlet.ParameterSetName -eq 'Scale') {
			$Resolutions.Scale.Width = $Width
			$Resolutions.Scale.Height = $Height
		}

		# Collect info about the input file
		$Probe = ffprobe -i $InPath 2>&1 | Out-String -Stream
		if ($LASTEXITCODE -ne 0) {
			# When ffprobe returns an error, display it and exit
			Write-Debug "FFPROBE EXITCODE: $LASTEXITCODE"
			Write-Error ($Probe | Select-Object -Last 1)
			return
		}

		# Get the total duration of the source video
		$Duration = $Probe | Select-String '^\s*Duration:' | Foreach-Object {
			$RxRes = $RxDur.Match($_)
			if ($RxRes.Success) {
				[pscustomobject]@{
					Hour        = [int]::Parse(($RxRes.Groups['HOUR'].Value))
					Minute      = [int]::Parse(($RxRes.Groups['MINUTE'].Value))
					Second      = [int]::Parse(($RxRes.Groups['SECOND'].Value))
					MilliSecond = [int]::Parse(($RxRes.Groups['MILLISECOND'].Value))
				}
			}
		}
		$TotalDuration = ($Duration.Hour * 3600000) + ($Duration.Minute * 60000) + ($Duration.Second * 1000) + $Duration.MilliSecond

		# FFMPEG Parameters
		$Arguments = @(
			"-i", "$InPath"			# Input file
			"-c:v", "libx265"		# HEVC/X.265 video compression
			"-vtag", "hvc1"			# HEVC/X.265 video compression
			"-crf", "23"				# Default quality/medium
			"-c:a", "aac"			# AAC Audio
			"-nostdin"				# Disable stdin (causing FFMPEG to fail if the output file exists)
		)

		# Scaling parameters
		$Width = $Resolutions[$PSCmdlet.ParameterSetName].Width
		$Height = $Resolutions[$PSCmdlet.ParameterSetName].Height
		if ($null -ne $Width -and $null -ne $Height) {
			$ScaleMessage = "Downscaling to $($PSCmdlet.ParameterSetName) ($Width x $Height) - preserving the original aspect ratio"
			# Scale to desired resolution (preserving aspect ratio), but only if original was bigger than that resolution
			$Arguments += , "-vf", "scale='if((gt(iw,$Width)+gt(ih,$Height))*gt(iw,ih),$Width,-2)':'if((gt(iw,$Width)+gt(ih,$Height))*gt(iw,ih),-2,$Width)':flags=lanczos"

			<#
			#"-vf","scale=1920:-2:flags=lanczos"	# Scale to 1920*x (preserving original aspect ratio)
			#"-vf", "scale=-2:-2:flags=lanczos"		# Scale to: original resolution (using multiples of 2)
			#"-vf", "scale='if((gt(iw,1920)+gt(ih,1080))*gt(iw,ih),1920,-2)':'if((gt(iw,1920)+gt(ih,1080))*gt(iw,ih),-2,1920)':flags=lanczos"	# Scale to 1920*1080 or 1080*1920, preserving aspect ratio, but only if original was bigger than that resolution
			#>
		}
		else {
			$ScaleMessage = "Preserving the original resolution"
		}

		# Select the compression preset
		if ($Fast.IsPresent -and $Fast) {
			$Arguments += , "-preset", "fast"		# Faster compression
		}
		else {
			$Arguments += , "-preset", "slow"		# Better compression
		}

		# Force overwriting target file
		if ($Force.IsPresent -and $Force) {
			$Arguments += , "-y"		# Force "yes" to all questions -> causes FFMPEG to overwrite output file if it exists
		}

		# Run in test mode, encoding the first 3 seconds of the inout file
		if ($Test.IsPresent -and $Test) {
			$Arguments += , "-t", "3"	# Force encoding of the first 3 seconds -> good for testing on a small smaple
		}

		# Process MetaData
		if ($NoMetaData.IsPresent -and $NoMetaData) {
			# Skip original MetaData, but add GPS location and creation_time
			$Probe | Foreach-Object {
				# Capture MOV metadata's GPS location
				$_ | Select-String 'com.apple.quicktime.location.ISO6709\s*:' | Foreach-Object {
					$_ -replace '^.*com.apple.quicktime.location.ISO6709\s*:\s*(?<GPS>.*)/.*$', 'location=$1'
				}
				# Capture MP4 metadata's GPS location
				$_ | Select-String '^\s*location\s*:' | Foreach-Object {
					$_ -replace '^\s*location\s*(?<GPS>.*)/.*$', 'location=$1'
				}
				# Capture metadata's creation_time
				$_ | Select-String '^\s*creation_time\s*:' | Foreach-Object {
					$_ -replace '^\s*creation_time\s*:\s*(?<TIME>.+)\s*$', 'creation_time=$1'
				}
			} | Select-Object -Unique | Where-Object {
				$null -ne $_ -and -not [string]::IsNullOrEmpty("$_".Trim())
			} | Foreach-Object {
				Write-Verbose "Adding metadata: $_"
				$Arguments += , '-metadata', $_
			}
		}
		else {
			# Copy original MetaData
			$Arguments += , "-map_metadata", "0:g"
			$Arguments += , "-map_metadata:s:v", "0:s:v"
			$Arguments += , "-map_metadata:s:a", "0:s:a"
			$Arguments += , "-movflags", "use_metadata_tags"	# Include MOV (apple) metadata
		}

		# Set the Output file's path
		$Arguments += , $OutPath	# Output file

		# Recompress using HEVC, optionally downscaling when the original is greater than the desired resolution
		if (($Force.IsPresent -and $Force) -or -not (Test-Path $OutPath) -or $PSCmdlet.ShouldProcess($OutPath, "Overwrite file")) {
			$OldConfirmPreference = $ConfirmPreference
			$ConfirmPreference = $false	# Disable "Confirm" for operation Tee-Object -Variable
			try {
				& ffmpeg $Arguments 2>&1 | Out-String -Stream | Tee-Object -Variable FFMPEG_OUT | Foreach-Object {
					$RxRes = $RxTime.Match($_)
					if ($RxRes.Success) {
						$CurrentDuration = [pscustomobject]@{
							Hour        = [int]::Parse(($RxRes.Groups['HOUR'].Value))
							Minute      = [int]::Parse(($RxRes.Groups['MINUTE'].Value))
							Second      = [int]::Parse(($RxRes.Groups['SECOND'].Value))
							MilliSecond = [int]::Parse(($RxRes.Groups['MILLISECOND'].Value))
						}
						$CurrentDuration = ($CurrentDuration.Hour * 3600000) + ($CurrentDuration.Minute * 60000) + ($CurrentDuration.Second * 1000) + $CurrentDuration.MilliSecond

						# Write-Warning ($CurrentDuration / $TotalDuration * 100)
						Write-Progress -Activity "$($Item.Name)" -Status "Encoding to HEVC (x.265) $ScaleMessage" -CurrentOperation $_ -PercentComplete ($CurrentDuration / $TotalDuration * 100)
					}

					$_ | Write-Verbose
				}
			}
			finally {
				$ConfirmPreference = $OldConfirmPreference
				Write-Progress -Activity "$($Item.Name)" -Status "Done" -Completed
			}
			if ($LASTEXITCODE -ne 0) {
				# When ffmpeg returns an error, display it and exit
				Write-Debug "FFMPEG EXITCODE: $LASTEXITCODE"
				Write-Error ($FFMPEG_OUT | Select-Object -Last 1)
				return
			}

			# Copy Last modification date
			(Get-Item $OutPath).LastWriteTime = $Item.LastWriteTime

			# Verbose dump the output file information
			ffprobe -i $OutPath 2>&1 | Out-String -Stream | Write-Verbose

			# Return the items (Original and Resized)
			[pscustomobject]@{
				Original = $Item
				Resized  = (Get-Item $OutPath)
			}
		}
	}
	Begin {
        # Test if ffmpeg and ffprobe are installed
		try {
			Get-Command ffprobe -ErrorAction Stop | Out-Null
			Get-Command ffmpeg -ErrorAction Stop | Out-Null
		}
		catch {
			throw "ffmpeg or ffprobe are missing, please install and make sure they are added to your PATH"
		}

        # Regex to capture the duration of the video
		$RxDur = [regex]::new('^\s*Duration:\s*(?<HOUR>\d+):(?<MINUTE>\d+):(?<SECOND>\d+)\.(?<MILLISECOND>\d+),')
		$RxTime = [regex]::new('\stime=(?<HOUR>\d+):(?<MINUTE>\d+):(?<SECOND>\d+)\.(?<MILLISECOND>\d+)\s')

        # Predefined resolutions
		$Resolutions = @{
			HD      = @{
				Width  = 1280
				Height = 720
			}
			FHD     = @{
				Width  = 1920
				Height = 1080
			}
			'2K'    = @{
				Width  = 2048
				Height = 1080
			}
			'4K'    = @{
				Width  = 3840
				Height = 2160
			}
			'8K'    = @{
				Width  = 7680
				Height = 4320
			}
			'10K'   = @{
				Width  = 10240
				Height = 4320
			}
			NoScale = @{
				Width  = $null
				Height = $null
			}
			Scale   = @{    # Custom scale, set at runtime
				Width  = $null  
				Height = $null
			}
		}
	}
}