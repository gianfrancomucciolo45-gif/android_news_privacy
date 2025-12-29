# Background Sync - Android News

Sistema completo di sincronizzazione in background con WorkManager, foreground service e sync intelligente.

## 📋 Funzionalità

### ✅ Implementato

1. **WorkManager Integration**
   - Sync periodico automatico
   - Task scheduling intelligente
   - Background constraints (WiFi, batteria)
   - Retry policy con exponential backoff

2. **Foreground Service**
   - Download articoli con notifica persistente
   - Progress tracking in tempo reale
   - Notifiche di completamento/errore
   - Cancellazione automatica dopo 3 secondi

3. **Smart Sync**
   - Frequenza adattiva basata su pattern di utilizzo
   - Analytics letture giornaliere
   - Ottimizzazione risparmio batteria
   - Sync solo su WiFi per immagini

4. **Background Image Preload**
   - Download immagini degli ultimi articoli
   - Cache persistente con CachedNetworkImage
   - Compressione automatica
   - Solo su rete non misurata

5. **Breaking News Notifications**
   - Rilevamento automatico notizie urgenti
   - Notifiche per articoli recenti (<30min)
   - Priorità fonti importanti
   - Deep linking verso articolo

6. **UI Settings**
   - BackgroundSyncSettingsScreen completa
   - Toggle abilita/disabilita sync
   - Slider frequenza personalizzabile (1-24h)
   - Statistiche in tempo reale
   - Sync manuale on-demand

## 🔧 Configurazione

### Dipendenze

```yaml
dependencies:
  workmanager: ^0.5.2
  flutter_local_notifications: ^19.5.0
  firebase_messaging: ^16.1.0
```

### Android Permissions

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Inizializzazione

```dart
// main.dart
final backgroundSync = BackgroundSyncService();
await backgroundSync.initialize();
```

## 📊 Architettura

### BackgroundSyncService

Servizio principale che gestisce:
- Registrazione task WorkManager
- Calcolo frequenza intelligente
- Tracking utilizzo utente
- Statistiche sync

### CallbackDispatcher

Top-level function per WorkManager:
- `periodic_news_sync`: Sync automatico periodico
- `download_articles`: Download manuale con foreground service
- `preload_images`: Preload immagini in background

### Smart Frequency Algorithm

```dart
// Utente molto attivo (>10 articoli/giorno)
frequency = baseFrequency * 0.75  // Sync più frequente

// Utente poco attivo (<3 articoli/giorno)
frequency = baseFrequency * 1.5   // Sync meno frequente

// Inattivo da >24h
frequency = baseFrequency * 1.5   // Riduzione frequenza
```

## 🎯 Utilizzo

### Tracking Letture Articoli

```dart
// Quando un utente legge un articolo
await BackgroundSyncService().trackArticleRead();
```

### Sync Manuale

```dart
// Avvia download manuale con notifica
await BackgroundSyncService().startManualSync(preloadImages: true);
```

### Preload Immagini

```dart
// Precarica immagini di una lista di articoli
await BackgroundSyncService().preloadImages(articles);
```

### Configurazione Frequenza

```dart
// Imposta sync ogni 6 ore
await BackgroundSyncService().setSyncFrequency(6);
```

### Abilita/Disabilita

```dart
// Disabilita completamente il background sync
await BackgroundSyncService().setEnabled(false);
```

## 📈 Statistiche

```dart
final stats = await BackgroundSyncService().getStats();

// Ritorna:
// {
//   'last_sync': timestamp,
//   'sync_count_today': int,
//   'daily_reads': int,
//   'enabled': bool,
//   'frequency_hours': int,
// }
```

## 🔔 Notifiche

### Download Progress

```dart
await NotificationService().showDownloadNotification(
  title: 'Download articoli',
  body: 'Scaricamento in corso...',
  progress: 45,  // 0-100
);
```

### Breaking News

Automaticamente rilevate e notificate quando:
- Articolo pubblicato <30 minuti fa
- Fonte prioritaria (TuttoAndroid, AndroidWorld, HDblog)
- Durante sync periodico

## 🎨 UI Components

### BackgroundSyncSettingsScreen

Schermata completa con:
- ✅ Switch abilita/disabilita
- ✅ Slider frequenza sync
- ✅ Statistiche (ultimo sync, sync oggi, letture)
- ✅ Pulsante sync manuale
- ✅ Info chips (Battery Friendly, WiFi Only, Smart Timing)

### Navigazione

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BackgroundSyncSettingsScreen(),
  ),
);
```

## ⚡ Performance

### Battery Optimization
- Sync solo con batteria >15%
- Preferenza rete WiFi per immagini
- Frequency capping basato su utilizzo
- WorkManager con constraint intelligenti

### Network Optimization
- Timeout 15s per richieste RSS
- Compression GZIP automatica
- Image optimization con flutter_image_compress
- Cache persistente locale

### Memory Management
- Lazy loading immagini
- Cleanup automatico cache old
- Limit cache size configurabile
- Background task isolation

## 🐛 Debugging

```dart
// Abilita debug mode in WorkManager
await Workmanager().initialize(
  callbackDispatcher,
  isInDebugMode: true,  // Mostra log dettagliati
);
```

### Log Utili

- `✅ BackgroundSyncService inizializzato`
- `🔄 Sync periodico registrato: ogni X ore`
- `📥 Sync manuale avviato`
- `✅ Sync periodico completato: X articoli`
- `📢 Notificato breaking news: ...`

## 📱 Testing

### Test Sync Manuale

1. Vai in Impostazioni > Sincronizzazione in Background
2. Tap "Sincronizza Ora"
3. Verifica notifica download
4. Controlla statistiche aggiornate

### Test Frequenza Adattiva

1. Leggi >10 articoli in un giorno
2. Verifica frequenza si riduce (più sync)
3. Non usare app per 24h
4. Verifica frequenza aumenta (meno sync)

### Test Breaking News

1. Simula articolo recente da fonte prioritaria
2. Attendi sync automatico
3. Verifica notifica "🔥 Breaking News"

## 🚀 Roadmap

### Prossime Versioni

- [ ] Sync selettivo per fonte
- [ ] Offline queue per articoli da scaricare
- [ ] Export/Import statistiche
- [ ] Sync on-demand per categoria
- [ ] Widget home screen con ultimo sync

## 📄 License

Parte del progetto Android News App - 2025

---

**Ultima modifica:** 20 dicembre 2025  
**Versione:** 1.0.0  
**Status:** ✅ Completato e Testato
