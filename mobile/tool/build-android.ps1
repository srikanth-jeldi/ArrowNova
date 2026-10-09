$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskSocketDirectory = Join-Path $taskProject '.build-tmp'
New-Item -ItemType Directory -Path $taskSocketDirectory -Force | Out-Null
$taskPreviousJavaOptions = $env:JAVA_TOOL_OPTIONS
try {
    # Short socket directory avoids a Windows JDK loopback error in long TEMP paths.
    $env:JAVA_TOOL_OPTIONS = ($taskPreviousJavaOptions + ' "-Djdk.net.unixdomain.tmpdir=' + $taskSocketDirectory + '"').Trim()
    Push-Location $taskProject
    try {
        flutter build apk --debug
        if ($LASTEXITCODE -ne 0) { throw 'Android debug build failed.' }
    } finally { Pop-Location }
} finally { $env:JAVA_TOOL_OPTIONS = $taskPreviousJavaOptions }
