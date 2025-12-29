<#
    Sincronizza screenshot reali nella cartella play_store_assets con nomi richiesti dalla Play Console.
    Se qualche file sorgente manca, viene segnalato.
#>

$src  = 'C:\src\Flutter Project\android_news\screenshots_reali'
$dest = 'C:\src\Flutter Project\android_news\tools\play_store_assets'

if (-not (Test-Path $dest)) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
}

# Mappatura suggerita (modifica se necessario)
$mapping = @{
    'home_screen.png'   = 'screenshot_1_home.png'
    'article_list.png'  = 'screenshot_2_articles.png'
    'screen_3.png'      = 'screenshot_3_settings.png'
    'screen_4.png'      = 'screenshot_4_sources.png'
}

Write-Host 'Copio e rinomino screenshot...' -ForegroundColor Cyan
foreach ($sourceName in $mapping.Keys) {
    $sourceFile = Join-Path $src $sourceName
    if (Test-Path $sourceFile) {
        $targetFile = Join-Path $dest $mapping[$sourceName]
        Copy-Item $sourceFile $targetFile -Force
        Write-Host "[OK] $sourceName -> $($mapping[$sourceName])" -ForegroundColor Green
    }
    else {
        Write-Host "[MISS] Manca $sourceName" -ForegroundColor Yellow
    }
}

Write-Host ('Operazione completata. Controlla la cartella: ' + $dest) -ForegroundColor Green
