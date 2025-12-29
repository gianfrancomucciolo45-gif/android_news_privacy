param([string]$DeviceId = 'Q4V4LRVWXGKBG6QS')
$OutputDir    = 'screenshots_reali'
$PlayStoreDir = 'tools\play_store_assets'

if (-not $env:Path.Contains('Android\Sdk\platform-tools')) {
  $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
}

Write-Host 'Detecting device screen size...' -ForegroundColor Cyan
$res = adb -s $DeviceId shell wm size | Select-String 'Physical size'
if ($res -match '(\d+)x(\d+)') {
  $W = [int]$matches[1]; $H = [int]$matches[2]
} else {
  $W = 1080; $H = 2400
}
Write-Host "Resolution: ${W}x${H}" -ForegroundColor Green

$CenterX  = [int]($W/2)
$ArticleY = [int]($H*0.35)
$TopRightX = [int]($W-100)
$TopRightY = 150
$SourcesY  = [int]($H*0.30)

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $PlayStoreDir | Out-Null

function Capture($num, $name, $delay=2) {
  Start-Sleep -Seconds $delay
  $temp = "/sdcard/screen_$num.png"
  $local = "$OutputDir/screenshot_${num}_$name.png"
  Write-Host "Capture $num -> $name" -ForegroundColor Cyan
  adb -s $DeviceId shell screencap -p $temp 2>&1 | Out-Null
  adb -s $DeviceId pull $temp $local 2>&1 | Out-Null
  adb -s $DeviceId shell rm $temp 2>&1 | Out-Null
  if (Test-Path $local) { Write-Host "[OK] $name" -ForegroundColor Green } else { Write-Host "[FAIL] $name" -ForegroundColor Red }
}

Write-Host 'Launching app...' -ForegroundColor Cyan
adb -s $DeviceId shell monkey -p com.mucciologianfranco.android_news 1 2>&1 | Out-Null
Start-Sleep -Seconds 5

Capture 1 'home' 1
adb -s $DeviceId shell input tap $CenterX $ArticleY 2>&1 | Out-Null
Capture 2 'articles' 3
adb -s $DeviceId shell input keyevent 4 2>&1 | Out-Null
adb -s $DeviceId shell input tap $TopRightX $TopRightY 2>&1 | Out-Null
Capture 3 'settings' 2
adb -s $DeviceId shell input keyevent 4 2>&1 | Out-Null
adb -s $DeviceId shell input tap $TopRightX $TopRightY 2>&1 | Out-Null
Start-Sleep -Seconds 2
adb -s $DeviceId shell input tap $CenterX $SourcesY 2>&1 | Out-Null
Capture 4 'sources' 2

Write-Host 'Copying screenshots to Play Store assets...' -ForegroundColor Cyan
Copy-Item "$OutputDir\screenshot_*.png" -Destination $PlayStoreDir -Force

Write-Host 'Summary:' -ForegroundColor Yellow
Get-ChildItem "$OutputDir\screenshot_*.png" | ForEach-Object { Write-Host "  -> $($_.Name)" -ForegroundColor Green }
Write-Host "Done. Assets in $PlayStoreDir" -ForegroundColor Green
