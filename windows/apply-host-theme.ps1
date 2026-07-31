#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$DistroName = "archlinux"
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$VersionsFile = Join-Path $RepositoryRoot "versions.env"

function Get-PinnedValue {
    param([Parameter(Mandatory = $true)][string]$Name)

    $line = Get-Content -LiteralPath $VersionsFile |
        Where-Object { $_ -match "^$([Regex]::Escape($Name))=" } |
        Select-Object -First 1
    if (-not $line -or $line -notmatch '^[A-Z0-9_]+="([^"]+)"$') {
        throw "Unable to read $Name from versions.env."
    }
    return $Matches[1]
}

Write-Host "Bloody Writer - Windows host theme" -ForegroundColor Red

$fontVersion = Get-PinnedValue -Name "NERD_FONT_VERSION"
$fontChecksum = Get-PinnedValue -Name "NERD_FONT_SHA256"
$fontFileName = "JetBrainsMonoNerdFontMono-Regular.ttf"
$fontUrl = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$fontVersion/patched-fonts/JetBrainsMono/Ligatures/Regular/$fontFileName"
$downloadPath = Join-Path $env:TEMP "bloody-writer-$fontFileName"

Write-Host "Downloading the pinned JetBrains Mono Nerd Font..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $fontUrl -OutFile $downloadPath -UseBasicParsing
$actualChecksum = (Get-FileHash -Algorithm SHA256 -LiteralPath $downloadPath).Hash.ToLowerInvariant()
if ($actualChecksum -ne $fontChecksum.ToLowerInvariant()) {
    throw "Nerd Font checksum verification failed."
}

$userFontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $userFontDirectory | Out-Null
$installedFontPath = Join-Path $userFontDirectory $fontFileName
Copy-Item -LiteralPath $downloadPath -Destination $installedFontPath -Force

$fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -Path $fontRegistryPath -Force | Out-Null
$fontRegistryProperties = @{
    Path = $fontRegistryPath
    Name = "JetBrainsMono Nerd Font Mono (TrueType)"
    Value = $installedFontPath
    PropertyType = "String"
    Force = $true
}
New-ItemProperty @fontRegistryProperties | Out-Null

if (-not ("BloodyWriter.NativeFont" -as [type])) {
    Add-Type -Namespace BloodyWriter -Name NativeFont -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
public static extern int AddFontResourceEx(string fileName, uint flags, System.IntPtr reserved);
'@
}
[BloodyWriter.NativeFont]::AddFontResourceEx($installedFontPath, 0x10, [IntPtr]::Zero) | Out-Null

$fragmentDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\Fragments\BloodyWriter"
New-Item -ItemType Directory -Force -Path $fragmentDirectory | Out-Null
$iconPath = Join-Path $fragmentDirectory "bloody-writer-logo.png"
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "assets\brand\bloody-writer-logo.png") -Destination $iconPath -Force

$fragment = [ordered]@{
    profiles = @(
        [ordered]@{
            guid = "{8f916408-9c85-48e2-a01f-b02188433b83}"
            name = "Bloody Writer - Arch WSL"
            commandline = "wsl.exe -d $DistroName"
            startingDirectory = "~"
            colorScheme = "Bloody Writer"
            icon = $iconPath
            font = [ordered]@{
                face = "JetBrainsMono Nerd Font Mono"
                size = 13
            }
        }
    )
    schemes = @(
        [ordered]@{
            name = "Bloody Writer"
            background = "#000000"
            foreground = "#FFF1F1"
            cursorColor = "#FF334D"
            selectionBackground = "#7A0014"
            black = "#000000"
            red = "#B00020"
            green = "#FF334D"
            yellow = "#FFB86C"
            blue = "#AFCBFF"
            purple = "#DFA0A0"
            cyan = "#FFF1F1"
            white = "#FFFFFF"
            brightBlack = "#632A2A"
            brightRed = "#FF334D"
            brightGreen = "#FF7587"
            brightYellow = "#FFD09A"
            brightBlue = "#D0E0FF"
            brightPurple = "#FF8F9C"
            brightCyan = "#FFF1F1"
            brightWhite = "#FFFFFF"
        }
    )
}

$fragmentPath = Join-Path $fragmentDirectory "bloody-writer.json"
$json = $fragment | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($fragmentPath, $json, [Text.UTF8Encoding]::new($false))
Remove-Item -LiteralPath $downloadPath -Force

Write-Host ""
Write-Host "Windows host theme installed." -ForegroundColor Green
Write-Host "Close every Windows Terminal window, reopen it, and select:"
Write-Host "  Bloody Writer - Arch WSL" -ForegroundColor White
