# Gradle expects platforms\android-37; some SDK installs only create android-37.0.
$ErrorActionPreference = 'Stop'
$sdkRoot = $env:ANDROID_SDK_ROOT
if (-not $sdkRoot) { $sdkRoot = $env:ANDROID_HOME }
if (-not $sdkRoot) { $sdkRoot = 'C:\Android\sdk' }

$platforms = Join-Path $sdkRoot 'platforms'
$target = Join-Path $platforms 'android-37'
$source = Join-Path $platforms 'android-37.0'

if (Test-Path $target) {
    Write-Host "OK: $target already exists."
    exit 0
}

if (-not (Test-Path $source)) {
    Write-Host "Install Android SDK Platform 37 (Android Studio > SDK Manager), then re-run this script."
    exit 1
}

cmd /c "mklink /J `"$target`" `"$source`""
Write-Host "Created junction: android-37 -> android-37.0"
