# ==============================================================================
# Gokul Shree - Flutter AAB (App Bundle) Generator & Version Manager
# ==============================================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  Gokul Shree - Flutter AAB (App Bundle) Release Generator" -ForegroundColor Yellow
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Read current version from pubspec.yaml
$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found at $pubspecPath"
    exit 1
}

$pubspecContent = Get-Content $pubspecPath -Raw
$currentVersionName = "2.3.5"
$currentBuildNumber = "1"

if ($pubspecContent -match '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+([0-9]+))?') {
    $currentVersionName = $matches[1]
    if ($matches[3]) {
        $currentBuildNumber = $matches[3]
    }
}

# 2. Calculate suggested incremented version
$parts = $currentVersionName.Split('.')
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]
$suggestedVersionName = "$major.$minor.$($patch + 1)"

# Epoch seconds ensures build number is strictly greater than 1791008929
$epochSeconds = [int][double]::Parse((Get-Date -UFormat %s))
$suggestedBuildNumber = "$epochSeconds"
$suggestedFull = "$suggestedVersionName+$suggestedBuildNumber"

# 3. Interactive prompt
Write-Host " Current pubspec version : " -NoNewline -ForegroundColor Gray
Write-Host "$currentVersionName+$currentBuildNumber" -ForegroundColor White
Write-Host " Play Console last code  : " -NoNewline -ForegroundColor Gray
Write-Host "1791008929 (new code must be strictly higher)" -ForegroundColor DarkYellow
Write-Host ""
Write-Host " Suggested Next Version   : " -NoNewline -ForegroundColor Green
Write-Host "$suggestedFull" -ForegroundColor Yellow
Write-Host "   - Version Name        : $suggestedVersionName" -ForegroundColor Gray
Write-Host "   - Version Code        : $suggestedBuildNumber (Epoch timestamp)" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------" -ForegroundColor DarkGray

$userInput = Read-Host " Press [ENTER] to use [$suggestedFull] or enter custom version"
$userInput = $userInput.Trim()

if ([string]::IsNullOrWhiteSpace($userInput)) {
    $chosenVersionName = $suggestedVersionName
    $chosenBuildNumber = $suggestedBuildNumber
} elseif ($userInput -match '^([0-9]+\.[0-9]+(\.[0-9]+)?)\+([0-9]+)$') {
    $chosenVersionName = $matches[1]
    $chosenBuildNumber = $matches[3]
} elseif ($userInput -match '^[0-9]+\.[0-9]+(\.[0-9]+)?$') {
    $chosenVersionName = $userInput
    $chosenBuildNumber = $suggestedBuildNumber
    Write-Host "   (No build code entered, using epoch code: $chosenBuildNumber)" -ForegroundColor Gray
} else {
    Write-Host " Invalid version format '$userInput'. Expected: X.Y.Z or X.Y.Z+Code" -ForegroundColor Red
    exit 1
}

$finalVersionString = "$chosenVersionName+$chosenBuildNumber"
Write-Host ""
Write-Host " Selected Version: $finalVersionString" -ForegroundColor Cyan

# 4. Update pubspec.yaml with the chosen version
$updatedContent = [regex]::Replace(
    $pubspecContent,
    '(?m)^version:\s*.*$',
    "version: $finalVersionString"
)
Set-Content -Path $pubspecPath -Value $updatedContent -NoNewline
Write-Host " Updated pubspec.yaml to: $finalVersionString" -ForegroundColor Green

# 5. Check release signing keystore
$keystorePath = Join-Path $PSScriptRoot "android\app\key.jks"
if (Test-Path $keystorePath) {
    Write-Host " Release signing keystore verified (android/app/key.jks)." -ForegroundColor Green
} else {
    Write-Host " Warning: android/app/key.jks not found." -ForegroundColor Yellow
}

# 6. Execute flutter build appbundle
Write-Host ""
Write-Host " Running: flutter build appbundle --release ..." -ForegroundColor Cyan
Write-Host "   - Build Name   : $chosenVersionName" -ForegroundColor Gray
Write-Host "   - Build Number : $chosenBuildNumber" -ForegroundColor Gray
Write-Host ""

$env:CI = "true"

$flutterArgs = @(
    "build",
    "appbundle",
    "--release",
    "--build-name=$chosenVersionName",
    "--build-number=$chosenBuildNumber"
)

& flutter $flutterArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host " Build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 7. Check output file
$aabPath = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aabPath) {
    $fileItem = Get-Item $aabPath
    $sizeMb = [math]::Round($fileItem.Length / 1MB, 2)

    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host " Output file : $aabPath" -ForegroundColor White
    Write-Host " File size   : $sizeMb MB" -ForegroundColor Yellow
    Write-Host " Version     : $chosenVersionName (VersionCode: $chosenBuildNumber)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Ready to upload to Google Play Console!" -ForegroundColor Green
    Write-Host "==============================================================" -ForegroundColor Green

    try {
        Set-Clipboard -Value $aabPath
        Write-Host " (File path copied to clipboard)" -ForegroundColor Gray
    } catch {
        # Clipboard not available
    }

    $openFolder = Read-Host " Open output folder in File Explorer? (Y/n)"
    if ($openFolder.Trim().ToLower() -ne 'n') {
        & explorer.exe /select,$aabPath
    }
} else {
    Write-Host " Build completed, but app-release.aab not found at $aabPath" -ForegroundColor Yellow
}
