<#
.SYNOPSIS
    This script installs Dell Command | Update for drivers and updates.

.DESCRIPTION
    This script will first check if the machine that this script is running on
    is a dell workstation. If it is it will continue, and if not, it will exit
    completely because it's either a vm or not a dell machine. It will then check
    if the software is already installed on the local machine. If not, it will
    download and install vcruntime140, then install Dell Command | Update via
    WinGet. Then the script will check again if the software is installed or not.

.NOTES
    Author: CL
    Date: 2025-10-21
    Version: 2.0
#>

# =============================================================================
# CONFIGURATION GLOBAL VARIABLES & PARAMETERS
# =============================================================================

# Define the date format for the log file
$Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# Define the path to the provisioning folder
$ProvisioningPath = "$env:PROGRAMDATA\Microsoft\Provisioning"

# Define the transcript file location
$TranscriptFile = "$ProvisioningPath\${Date}_dell-commandupdate-install-winget.txt"

# Define the name of the software to check
$SoftwareName = "Dell Command | Update"

# Define the package being installed
$winGetPackage = "Dell.CommandUpdate.Universal"

# Define the path to Desktop Installer
$winGetPath = Get-ChildItem "$env:PROGRAMFILES\WindowsApps" -Filter "Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe" |
    Sort-Object Name -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName + "\winget.exe" }

# Define the arguments for installing with winget
$winGetInstallArgs = @(
    "install",
    "--exact",
    "--id", $winGetPackage,
    #"--scope", "machine",
    "--silent",
    "--accept-source-agreements",
    "--accept-package-agreements",
    "--source", "winget",
    "--verbose-logs",
    "--disable-interactivity",
    "--log", "$ProvisioningPath\${Date}_dell-commandupdate-winget-log.txt"
)

# Define the URL for vcruntime140
$vcRuntimeURL = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

# Define the location of the downloaded installer
$vcRuntimeInstaller = "$ProvisioningPath\vc_redist.x64.exe"

# Define the arguments for installer
$vcRuntimeInstallerArgs = @(
    "/install",
    "/quiet",
    "/norestart",
    "/log", "$ProvisioningPath\${Date}_vcruntime140-install.txt"
) -join " "

# Define the file path for vcruntime140
$vcRuntimePath = "$env:WINDIR\System32\vcruntime140.dll"

# Define the file name for vcruntime140
$vcRuntimeName = "vcruntime140.dll"

# Define the manufacturer
$Manufacturer = (Get-CIMInstance Win32_ComputerSystem).Manufacturer

# Define the registry paths to the list of installed programs
$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Initialize an empty array to store the installed software
$InstalledSoftware = @()

# Get the list of installed programs from each registry path
foreach ($RegistryPath in $RegistryPaths)
{
    $InstalledSoftware += Get-ItemProperty -Path "$RegistryPath\*" -ErrorAction SilentlyContinue
}

# Check if the specified software is installed
$SoftwareInstalled = $InstalledSoftware | Where-Object { $_.DisplayName -like "*$SoftwareName*"}

$origEncoding = [System.Console]::OutputEncoding

# =============================================================================
# FUNCTIONS
# =============================================================================

# Powershell logging function with here-string and indentation cleanup
function Write-CleanLog
{
    param (
        [Parameter(Position = 0)]
        [string[]]$Messages,
        [string]$Color = "White" # Default color
    )

    # Build the log lines
    foreach ($msg in $Messages)
    {
        if ([string]::IsNullOrWhiteSpace($msg))
        {
            Write-Host "" # True blank line
        } else
        {
            $timestamp = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timestamp] $msg" -ForegroundColor $Color
        }
    }
}

# =============================================================================
# MAIN SCRIPT LOGIC
# =============================================================================

[System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Start a Log file
Start-Transcript -Path "$TranscriptFile"

Write-CleanLog @("", "Checking the manufacturer of computer...")
if ($Manufacturer -like "*Dell*")
{
    Write-CleanLog @("", "This is a `"$Manufacturer`" computer.") -Color Green
} else
{
    Write-CleanLog @("", "This is a `"$Manufacturer`" computer. Exiting script.") -Color Red
    Exit
}

# Check if software is installed
Write-CleanLog @("", "Checking if `"$SoftwareName`" is installed...")
if ($SoftwareInstalled)
{
    Write-CleanLog @("", "`"$SoftwareName`" is installed. Exiting script") -Color Red
    Exit
} else
{
    Write-CleanLog @("", "`"$SoftwareName is not installed.") -Color Green
}

# Check if vcruntime140.dll is located in C:\Windows\System32\
Write-CleanLog @("", "Checking if `"$vcRuntimePath`" exists...")
if (Test-Path $vcRuntimePath)
{
    Write-CleanLog @("", "`"$vcRuntimePath`" exists.") -Color Green
} else
{
    # vcruntime140.dll does not exist, so download
    Write-CleanLog @("", "`"$vcRuntimePath`" does not exist. Downloading `"$vcRuntimeName`"...")
    # Save the original progress preference for restoration
    # Using $global: ensures the variable is set regardless of the function's scope
    $originalProgressPreference = $global:ProgressPreference
    $global:ProgressPreference = 'SilentlyContinue'
    try
    {
        try
        {
            Write-CleanLog @(
                "",
                "Invoke-WebRequest -Uri `"$vcRuntimeURL`" -OutFile `"$vcRuntimeInstaller`" -ErrorAction Stop"
            ) -Color DarkGray
            Invoke-WebRequest -Uri $vcRuntimeURL -OutFile $vcRuntimeInstaller -ErrorAction Stop
        } catch
        {
            Write-CleanLog @(
                "",
                (
                    "Error occurred while downloading: $($_.Exception.Message) " +
                    "Exiting script."
                )
            ) -Color Red
            Exit 1
        }
    } finally
    {
        # Restore original progress preference
        $global:ProgressPreference = $originalProgressPreference
    }

    # if vcruntime140.dll installer downloaded, then install
    if (Test-Path $vcRuntimeInstaller)
    {
        Write-CleanLog @("", "`"$vcRuntimeInstaller`" exists.") -Color Green
        Write-CleanLog @("", "Installing `"$vcRuntimeName`" silently...")
        Write-CleanLog @(
            "",
            (
                "Start-Process -FilePath `"$vcRuntimeInstaller`" " +
                "-ArgumentList `"$vcRuntimeInstallerArgs`" -Wait -NoNewWindow"
            )
        ) -Color DarkGray
        Start-Process -FilePath $vcRuntimeInstaller -ArgumentList $vcRuntimeInstallerArgs -Wait -NoNewWindow
    } else
    {
        Write-CleanLog @(
            "",
            (
                "`"$vcRuntimeInstaller`" does not exist. " +
                "Something went wrong and the executable did not download."
            )
            "",
            "Exiting script."
        ) -Color Red
        Exit 1
    }
}

# Check again if vcruntime140.dll is located in C:\Windows\System32\
if (Test-Path $vcRuntimePath)
{
    # Installing software via Winget
    if (Test-Path $winGetPath)
    {
        Write-CleanLog @("", "Installing `"$winGetPackage`" via winget...")
        Write-CleanLog @("", "& `"$winGetPath`" $($winGetInstallArgs -join ' ')", "") -Color DarkGray
        try
        {
            & $winGetPath @winGetInstallArgs
            Write-CleanLog ""
        } catch
        {
            Write-CleanLog @("", "Error running winget: $($_.Exception.Message)") -Color Red
        }
    } else
    {
        Write-CleanLog @("", "`"$winGetPath`" does not exist.") -Color Red
    }
} else
{
    Write-CleanLog @(
        "",
        (
            "`"$vcRuntimePath`" does not exist. Something went wrong after " +
            "downloading and installing `"$vcRuntimeName`"."
        )
        "",
        "Exiting script."
    ) -Color Red
    Exit 1
}

$maxduration = 300
$starttime = Get-Date

while ($true)
{
    Write-CleanLog @("Checking if `"$softwarename`" is installed...")
    $InstalledSoftware = @()
    foreach ($RegistryPath in $RegistryPaths)
    {
        $InstalledSoftware += Get-ItemProperty -Path "$RegistryPath\*" -ErrorAction SilentlyContinue
    }
    $SoftwareInstalled = $InstalledSoftware | Where-Object { $_.DisplayName -like "*$SoftwareName*"}

    if ($SoftwareInstalled)
    {
        Write-CleanLog @("", "`"$SoftwareName`" is installed. Continuing the script...") -Color Green
        Break
    } else
    {
        $ElapsedTime = (Get-Date) - $StartTime
        if ($ElapsedTime.TotalSeconds -ge $MaxDuration)
        {
            Write-CleanLog @("`"$SoftwareName`" is not installed after 5 minutes.") -Color Red
            Exit 1
        }
        Start-Sleep -Seconds 60
    }
}

[System.Console]::OutputEncoding = $origEncoding

Write-CleanLog @("", "Cleaning up files from `"$ProvisioningPath`", if any...", "")

if (Test-Path $vcRuntimeInstaller)
{
    Write-CleanLog @("Remove-Item -Path `"$vcRuntimeInstaller`" -Force") -Color DarkGray
    Remove-Item -Path $vcRuntimeInstaller -Force
}

if (Test-Path "$ProvisioningPath\${Date}_vcruntime140-install.txt")
{
    Write-CleanLog @("Remove-Item -Path `"$ProvisioningPath\${Date}_vcruntime140*`" -Force") -Color DarkGray
    Remove-Item -Path "$ProvisioningPath\${Date}_vcruntime140*" -Force
}

Write-CleanLog @("", "Exiting script.", "")
Write-Host "Transcript stopped, output file is $TranscriptFile"
Stop-Transcript

Exit


