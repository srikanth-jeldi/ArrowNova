param()
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $taskProject 'android/key.properties'))) {
    throw 'Missing upload signing configuration: android/key.properties'
}
$taskSocketDirectory = Join-Path $taskProject '.build-tmp'
New-Item -ItemType Directory -Path $taskSocketDirectory -Force | Out-Null
$taskPreviousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    $env:JAVA_TOOL_OPTIONS = ($taskPreviousJavaOptions + ' "-Djdk.net.unixdomain.tmpdir=' + $taskSocketDirectory + '"').Trim()
    Push-Location $taskProject
    try {
        $taskVersion = ((Select-String -Path 'pubspec.yaml' -Pattern '^version:').Line -replace '^version:\s*', '').Trim()
        $taskDiagnostics = Join-Path $taskProject "build/release-diagnostics/$taskVersion/store"
        New-Item -ItemType Directory -Path $taskDiagnostics -Force | Out-Null
        flutter build appbundle --release --dart-define=LIVE_ADS=true --dart-define=STORE_RELEASE=true "--split-debug-info=$taskDiagnostics/dart"
        if ($LASTEXITCODE -ne 0) { throw 'Signed Play Store bundle build failed.' }
        # Keep complete crash diagnostics alongside each distributed release,
        # including Dart DWARF moved out of the shipped AOT libraries.
        $taskNative = Join-Path $taskProject 'build/app/intermediates/merged_native_libs/release/mergeReleaseNativeLibs/out/lib'
        if (-not (Test-Path -LiteralPath $taskNative)) { throw 'Missing native libraries for diagnostics archive.' }
        Compress-Archive -Path "$taskNative/*" -DestinationPath "$taskDiagnostics/native-libraries.zip" -Force
        Copy-Item -LiteralPath 'build/app/outputs/mapping/release/mapping.txt' -Destination "$taskDiagnostics/mapping.txt"
        & "$PSScriptRoot/compact-bundle.ps1"
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $taskPreviousJavaOptions }
