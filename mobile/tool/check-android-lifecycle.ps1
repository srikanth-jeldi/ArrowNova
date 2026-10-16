param(
    [string]$Serial = 'emulator-5556',
    [int]$Cycles = 20,
    [ValidateSet('com.epitomehub.arrownova.audit','com.epitomehub.arrownova')]
    [string]$Package = 'com.epitomehub.arrownova.audit',
    [string]$Output = 'E:/arrows puzzle/mobile/.build-tmp/audit-2026-10-16'
)
$ErrorActionPreference = 'Stop'
$taskAdb = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
$taskPackage = $Package
$taskActivity = "$taskPackage/com.epitomehub.arrownova.MainActivity"
New-Item -ItemType Directory -Path $Output -Force | Out-Null
function Invoke-QAAdb {
    $Arguments = $args
    $result = & $taskAdb -s $Serial @Arguments
    if ($LASTEXITCODE -ne 0) { throw "ADB failed: $Arguments" }
    return $result
}
$taskInitialPid = (Invoke-QAAdb shell pidof $taskPackage).Trim()
if (-not $taskInitialPid) { throw 'Open ArrowNova QA first.' }
$taskRows = @()
for ($i = 1; $i -le $Cycles; $i++) {
    Invoke-QAAdb shell input keyevent 3 | Out-Null
    Start-Sleep -Seconds 2
    Invoke-QAAdb shell am start -W -n $taskActivity | Out-Null
    Start-Sleep -Seconds 2
    $taskPid = (Invoke-QAAdb shell pidof $taskPackage).Trim()
    $taskRows += [pscustomobject]@{Cycle=$i; ProcessId=$taskPid; SameProcess=($taskPid -eq $taskInitialPid)}
    if ($taskPid -ne $taskInitialPid) { throw "App process changed during cycle $i" }
    if ($i % 5 -eq 0) { Write-Output "Background/resume $i / $Cycles passed" }
}
Invoke-QAAdb shell input keyevent 223 | Out-Null
Start-Sleep -Seconds 15
Invoke-QAAdb shell input keyevent 224 | Out-Null
Invoke-QAAdb shell wm dismiss-keyguard | Out-Null
Invoke-QAAdb shell am start -W -n $taskActivity | Out-Null
Start-Sleep -Seconds 3
$taskFinalPid = (Invoke-QAAdb shell pidof $taskPackage).Trim()
$taskRows | Export-Csv -NoTypeInformation -LiteralPath "$Output/lifecycle-cycles.csv"
Invoke-QAAdb shell dumpsys activity exit-info $taskPackage | Set-Content "$Output/exit-info.txt"
Invoke-QAAdb logcat -d -v threadtime | Set-Content "$Output/lifecycle-logcat.txt"
Invoke-QAAdb shell dumpsys meminfo $taskPackage | Set-Content "$Output/meminfo.txt"
Invoke-QAAdb shell screencap -p /data/local/tmp/arrownova-qa-lifecycle.png | Out-Null
Invoke-QAAdb pull /data/local/tmp/arrownova-qa-lifecycle.png "$Output/lifecycle.png" | Out-Null
if ($taskFinalPid -ne $taskInitialPid) { throw 'App process changed after screen off/on.' }
Write-Output "PASS: $Cycles background/resume cycles and screen off/on retained process $taskFinalPid. Inspect screenshot and logs for UI state and ANRs."
