param([switch]$DebugBuild, [switch]$LiveAds)

$ErrorActionPreference = 'Stop'
if ($DebugBuild -and $LiveAds) { throw 'Use test ads for debug builds.' }
$taskAdMode = if ($LiveAds) { '--dart-define=LIVE_ADS=true' } else { '--dart-define=LIVE_ADS=false' }
$taskProject = Split-Path -Parent $PSScriptRoot
$taskSocketDirectory = Join-Path $taskProject '.build-tmp'
New-Item -ItemType Directory -Path $taskSocketDirectory -Force | Out-Null
$taskPreviousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    # Short socket directory avoids a Windows JDK loopback error in long TEMP paths.
    $env:JAVA_TOOL_OPTIONS = ($taskPreviousJavaOptions + ' "-Djdk.net.unixdomain.tmpdir=' + $taskSocketDirectory + '"').Trim()
    Push-Location $taskProject
    try {
        if ($DebugBuild) {
            flutter build apk --debug
        } else {
            # Deliver one optimized phone architecture, not a universal debug APK.
            flutter build apk --release --split-per-abi --target-platform android-arm64 $taskAdMode
        }
        if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $taskPreviousJavaOptions }
