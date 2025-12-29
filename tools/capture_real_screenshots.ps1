# Script per catturare screenshot reali dall'app sul telefono
# Richiede: dispositivo Android connesso via USB con debug USB abilitato

$deviceId = "Q4V4LRVWXGKBG6QS"
$outputDir = ".\screenshots_reali"
$playStoreDir = ".\tools\play_store_assets"

# Aggiungi platform-tools al PATH se non presente
if (-not $env:Path.Contains("Android\Sdk\platform-tools")) {
    $env:Path += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
}

# Verifica dispositivo connesso
Write-Host "Verifica dispositivo connesso..."
$devices = adb devices | Select-String "device$"
if (-not $devices) {
    Write-Host "ERRORE: Nessun dispositivo connesso. Collega il telefono e abilita USB debugging." -ForegroundColor Red
    exit 1
}

Write-Host "Dispositivo trovato: $deviceId" -ForegroundColor Green

# Crea directory output se non esiste
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Write-Host "`nIstruzioni:" -ForegroundColor Yellow
Write-Host "1. Assicurati che l'app Android News sia aperta sul telefono"
Write-Host "2. Naviga alla schermata HOME e premi INVIO quando pronto..."
Read-Host

Write-Host "Cattura screenshot 1: Home..." -ForegroundColor Cyan
adb -s $deviceId shell screencap -p /sdcard/screen_1.png
adb -s $deviceId pull /sdcard/screen_1.png "$outputDir\screenshot_1_home.png"
adb -s $deviceId shell rm /sdcard/screen_1.png
Write-Host "✓ Screenshot 1 salvato" -ForegroundColor Green
Start-Sleep -Seconds 2

Write-Host "`n3. Naviga a una lista di ARTICOLI e premi INVIO..."
Read-Host

Write-Host "Cattura screenshot 2: Articoli..." -ForegroundColor Cyan
adb -s $deviceId shell screencap -p /sdcard/screen_2.png
adb -s $deviceId pull /sdcard/screen_2.png "$outputDir\screenshot_2_articles.png"
adb -s $deviceId shell rm /sdcard/screen_2.png
Write-Host "✓ Screenshot 2 salvato" -ForegroundColor Green
Start-Sleep -Seconds 2

Write-Host "`n4. Apri IMPOSTAZIONI e premi INVIO..."
Read-Host

Write-Host "Cattura screenshot 3: Impostazioni..." -ForegroundColor Cyan
adb -s $deviceId shell screencap -p /sdcard/screen_3.png
adb -s $deviceId pull /sdcard/screen_3.png "$outputDir\screenshot_3_settings.png"
adb -s $deviceId shell rm /sdcard/screen_3.png
Write-Host "✓ Screenshot 3 salvato" -ForegroundColor Green
Start-Sleep -Seconds 2

Write-Host "`n5. Apri SORGENTI NOTIZIE e premi INVIO..."
Read-Host

Write-Host "Cattura screenshot 4: Sorgenti..." -ForegroundColor Cyan
adb -s $deviceId shell screencap -p /sdcard/screen_4.png
adb -s $deviceId pull /sdcard/screen_4.png "$outputDir\screenshot_4_sources.png"
adb -s $deviceId shell rm /sdcard/screen_4.png
Write-Host "✓ Screenshot 4 salvato" -ForegroundColor Green

# Copia screenshot in play_store_assets
Write-Host "`nCopia screenshot in play_store_assets..." -ForegroundColor Cyan
Copy-Item "$outputDir\screenshot_*.png" -Destination $playStoreDir -Force

Write-Host "`n✓ COMPLETATO! Screenshot catturati e copiati in:" -ForegroundColor Green
Write-Host "  - $outputDir" -ForegroundColor White
Write-Host "  - $playStoreDir" -ForegroundColor White

# Mostra dimensioni screenshot
Write-Host "`nDimensioni screenshot:" -ForegroundColor Yellow
Get-ChildItem "$outputDir\screenshot_*.png" | ForEach-Object {
    $img = [System.Drawing.Image]::FromFile($_.FullName)
    Write-Host "  $($_.Name): $($img.Width)x$($img.Height)"
    $img.Dispose()
}

Write-Host "`nNOTA: Se le dimensioni non sono corrette per Play Store (1080x1920)," -ForegroundColor Yellow
Write-Host "      puoi ridimensionarle con uno strumento di editing immagini." -ForegroundColor Yellow
