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
        flutter build appbundle --release --dart-define=LIVE_ADS=true --dart-define=STORE_RELEASE=true
        if ($LASTEXITCODE -ne 0) { throw 'Signed Play Store bundle build failed.' }
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $taskPreviousJavaOptions }
