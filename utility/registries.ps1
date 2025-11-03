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

# Restore Windows 10 context menu in Windows 11
Write-CleanLog @("", "Restore Windows 10 context menu in Windows 11")
Write-CleanLog @(
    "",
    "New-Item -Path `"HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`" -Force | Out-Null",
    "Set-ItemProperty -Path `"HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`" -Name `"(default)`" -Value """,
    "New-Item -Path `"HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`" -Force | Out-Null",
    "Set-ItemProperty -Path `"HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32`" -Name `"(default)`" -Value """
) -Color DarkGray

New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Name "(default)" -Value ""
New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -Value ""

# Enable Dark Mode and disable Transparency
$personalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Write-CleanLog @("", "Enable Dark Mode and disable Transparency")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"$personalizePath`" -Name `"AppsUseLightTheme`" -Value 0 -Type DWord",
    "Set-ItemProperty -Path `"$personalizePath`" -Name `"SystemUsesLightTheme`" -Value 0 -Type DWord",
    "Set-ItemProperty -Path `"$personalizePath`" -Name `"EnableTransparency`" -Value 0 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path $personalizePath -Name "AppsUseLightTheme" -Value 0 -Type DWord
Set-ItemProperty -Path $personalizePath -Name "SystemUsesLightTheme" -Value 0 -Type DWord
Set-ItemProperty -Path $personalizePath -Name "EnableTransparency" -Value 0 -Type DWord

# Disable Wallpaper compression
Write-CleanLog @("", "Disable Wallpaper compression")
Write-CleanLog @("", "Set-ItemProperty -Path `"HKCU:\Control Panel\Desktop`" -Name `"JPEGQualityImport`" -Value 0 -Type DWord") -Color DarkGray

Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "JPEGQualityImport" -Value 0 -Type DWord

# Remove duplicate external drive entries
Write-CleanLog @("", "Remove duplicate external drive entries")
Write-CleanLog @(
    "",
    "Remove-Item -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}`" -Force -ErrorAction SilentlyContinue",
    "Remove-Item -Path `"HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}`" -Force -ErrorAction SilentlyContinue"
) -Color DarkGray

Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}" -Force -ErrorAction SilentlyContinue

# Show drive letters before drive names
Write-CleanLog @("", "Show drive letters before drive names")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer`" -Name `"ShowDriveLettersFirst`" -Value 4 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowDriveLettersFirst" -Value 4 -Type DWord

# Enable compact view and launch File Explorer to "This PC"
$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Write-CleanLog @("", "Enable compact view and launch File Explorer to 'This PC'")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"$advancedPath`" -Name `"UseCompactMode`" -Value 1 -Type DWord",
    "Set-ItemProperty -Path `"$advancedPath`" -Name `"LaunchTo`" -Value 1 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path $advancedPath -Name "UseCompactMode" -Value 1 -Type DWord
Set-ItemProperty -Path $advancedPath -Name "LaunchTo" -Value 1 -Type DWord

# Disable numerical sorting in File Explorer
Write-CleanLog @("", "Disable numerical sorting in File Explorer")
Write-CleanLog @(
    "",
    "Remove-ItemProperty -Path `"HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoStrCmpLogical`" -ErrorAction SilentlyContinue",
    "Remove-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`" -Name `"NoStrCmpLogical`" -ErrorAction SilentlyContinue"
) -Color DarkGray

Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStrCmpLogical" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStrCmpLogical" -ErrorAction SilentlyContinue

# Set UAC elevation prompt behavior for standard users
Write-CleanLog @("", "Set UAC elevation prompt behavior for standard users")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"ConsentPromptBehaviorUser`" -Value 1 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorUser" -Value 1 -Type DWord

# Set UAC elevation prompt behavior for administrators in Admin Approval Mode
Write-CleanLog @("", "Set UAC elevation prompt behavior for administrators in Admin Approval Mode")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"ConsentPromptBehaviorAdmin`" -Value 1 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 1 -Type DWord

# Ensure prompts appear on the secure desktop
Write-CleanLog @("", "Ensure prompts appear on the secure desktop")
Write-CleanLog @(
    "",
    "Set-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System`" -Name `"PromptOnSecureDesktop`" -Value 1 -Type DWord"
) -Color DarkGray

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 1 -Type DWord

