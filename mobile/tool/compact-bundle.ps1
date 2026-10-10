param()
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskVersion = ((Select-String -Path "$taskProject/pubspec.yaml" -Pattern '^version:').Line -replace '^version:\s*', '').Trim()
$taskDiagnostics = Join-Path $taskProject "build/release-diagnostics/$taskVersion/store"
New-Item -ItemType Directory -Path $taskDiagnostics -Force | Out-Null
$taskInput = Join-Path $taskProject 'build/app/outputs/bundle/release/app-release.aab'
$taskOutput = Join-Path $taskProject 'build/app/outputs/bundle/release/app-release-compact.aab'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskSource = [IO.Compression.ZipFile]::OpenRead($taskInput)
$taskOutputStream = [IO.File]::Create($taskOutput)
$taskCompact = [IO.Compression.ZipArchive]::new($taskOutputStream, [IO.Compression.ZipArchiveMode]::Create)
$taskSymbolStream = [IO.File]::Create("$taskDiagnostics/native-debug-symbols.zip")
$taskSymbols = [IO.Compression.ZipArchive]::new($taskSymbolStream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($taskEntry in $taskSource.Entries) {
        if ($taskEntry.FullName -match '^META-INF/([^/]+\.(SF|RSA|DSA|EC)|MANIFEST\.MF)$') { continue }
        if ($taskEntry.FullName.EndsWith('/')) { continue }
        $taskNativePrefix = 'BUNDLE-METADATA/com.android.tools.build.debugsymbols/'
        if ($taskEntry.FullName.StartsWith($taskNativePrefix)) {
            $taskDestination = $taskSymbols.CreateEntry($taskEntry.FullName.Substring($taskNativePrefix.Length), [IO.Compression.CompressionLevel]::Optimal)
        } elseif ($taskEntry.FullName -eq 'BUNDLE-METADATA/com.android.tools.build.obfuscation/proguard.map') {
            [IO.Compression.ZipFileExtensions]::ExtractToFile($taskEntry, "$taskDiagnostics/mapping.txt", $true)
            continue
        } else {
            $taskDestination = $taskCompact.CreateEntry($taskEntry.FullName, [IO.Compression.CompressionLevel]::Optimal)
        }
        $taskRead = $taskEntry.Open()
        $taskWrite = $taskDestination.Open()
        try { $taskRead.CopyTo($taskWrite) } finally { $taskWrite.Dispose(); $taskRead.Dispose() }
    }
} finally {
    $taskSymbols.Dispose(); $taskSymbolStream.Dispose()
    $taskCompact.Dispose(); $taskOutputStream.Dispose(); $taskSource.Dispose()
}
# Only diagnostics/signatures are detached. Runtime modules are untouched.
# Re-sign using the same upload key; credentials never appear in command arguments.
$taskProperties = ConvertFrom-StringData ([IO.File]::ReadAllText("$taskProject/android/key.properties"))
$taskStore = [IO.Path]::GetFullPath((Join-Path "$taskProject/android" $taskProperties.storeFile))
$taskSigner = if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME/bin/jarsigner.exe")) {
    "$env:JAVA_HOME/bin/jarsigner.exe"
} else { (Get-Command jarsigner -ErrorAction Stop).Source }
$taskOldStorePass = $env:ARROWNOVA_SIGN_STORE_PASS
$taskOldKeyPass = $env:ARROWNOVA_SIGN_KEY_PASS
try {
    $env:ARROWNOVA_SIGN_STORE_PASS = $taskProperties.storePassword
    $env:ARROWNOVA_SIGN_KEY_PASS = $taskProperties.keyPassword
    & $taskSigner -keystore $taskStore -storepass:env ARROWNOVA_SIGN_STORE_PASS -keypass:env ARROWNOVA_SIGN_KEY_PASS $taskOutput $taskProperties.keyAlias
    if ($LASTEXITCODE -ne 0) { throw 'Compact bundle signing failed.' }
    & $taskSigner -verify $taskOutput
    if ($LASTEXITCODE -ne 0) { throw 'Compact bundle signature verification failed.' }
} finally {
    $env:ARROWNOVA_SIGN_STORE_PASS = $taskOldStorePass
    $env:ARROWNOVA_SIGN_KEY_PASS = $taskOldKeyPass
    $taskProperties.Clear()
}
Write-Output "Compact bundle: $taskOutput"
Write-Output "Upload diagnostics separately if using this bundle: $taskDiagnostics"
