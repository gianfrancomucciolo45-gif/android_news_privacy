## Monetizzazione

- **Modello ibrido**: Free con pubblicità + Abbonamento Premium senza ads e con funzionalità avanzate.
- **Ads (Free tier)**: Banner contenuti, native ads nel feed, interstitial solo su eventi non-navigazionali (es. fine articolo), reward video opzionali per sblocchi temporanei. Frequency capping e brand safety.
- **Abbonamento Premium**: Rimozione totale ads, modalità lettura offline, temi esclusivi, raccolte salvate illimitate, alert breaking news prioritari, sincronizzazione multi-dispositivo.
- **Prezzi e paesi**: €3,49/mese, €24,99/anno (≈29% sconto). Introduzione iniziale in UE + USA, estensione graduale.
- **Prove e promo**: Trial 7 giorni, promo lancio -20% per 30 giorni, codice referral con 1 mese gratuito per entrambi.
- **Acquisti one-off**: Sblocchi singoli per funzionalità specifiche (es. esportazione PDF o pacchetti di temi) a €0,99–€2,49.
- **Consenso e compliance**: SDK consenso IAB TCF v2, flusso GDPR/CCPA, privacy-by-design, trasparenza su partner ad-tech.
- **Controllo qualità ads**: Bloccare categorie sensibili, evitare conflitti con contenuti editoriali, cooldown tra interstitial, limitare density nel feed.
- **Tecnico**: `google_mobile_ads` per AdMob, `in_app_purchase` (Play Billing v6+) per abbonamenti/IAP, Remote Config per layout ads e paywall, feature flags.
- **Analitiche e KPI**: ARPDAU (free), conversione a premium, churn 30/90gg, eCPM per placement, LTV per coorte, retention D1/D7/D30.
- **A/B test**: Paywall soft vs hard, posizione native ads, pricing annuale, durata trial; rollout 10%→50%→100%.
- **Rollout**: Alpha (QA), Beta (10% utenti), Produzione graduale con monitoraggio crash/ANR e segnalazioni policy.

### Checklist implementativa

- **Dipendenze**: Aggiungere `google_mobile_ads`, `in_app_purchase`, SDK consenso, Remote Config/Feature flags.
- **Servizi**: `AdService`, `BillingService`, `ConsentService`, `RemoteConfigService` in `lib/services/`.
- **UI**: Contenitori per banner/native, paywall screen, pagina abbonamento, badge Premium.
- **Paywall**: Soft gate dopo N articoli/die, hard gate su funzionalità premium, reward video come alternativa temporanea.
- **Sicurezza**: Verifica ricevute server-side (opzionale), gestione edge case cancellazioni/rimborsi.
- **Localizzazione**: Stringhe per monetizzazione in `l10n` con prezzi dinamici.
- **Telemetria**: Eventi `ad_impression`, `ad_click`, `subscription_start`, `subscription_renew`, `paywall_view`.

### Policy Play Store

- Conformità a norme su pubblicità, abbonamenti, raccolta dati; termini chiari, easy-cancel, pricing locale.
- Evitare ads ingannevoli o che interferiscono con navigazione; nessun interstitial su onboarding o azioni critiche.
- Mostrare stato abbonamento e gestione in-app, collegamento alle impostazioni Play.

### Obiettivi trimestrali

- T1: Integrare ads base + consenso, lanciare Beta 10%.
- T2: Abbonamenti + paywall soft, trial, pricing; A/B test.
- T3: Espansione paesi, ottimizzazione eCPM, introdurre reward video opzionali.
# 🚀 Android News App - Roadmap

## 📱 Informazioni Progetto
**Nome:** Android News  
**Framework:** Flutter 3.10.0+  
**Design:** Material Design 3 Expressive  
**Target:** Android (estendibile iOS/Web)  
**Ultimo aggiornamento:** 23 novembre 2025

---

## ✅ Completato

### 🎨 Setup & Design System
- [x] **Setup iniziale progetto Flutter**
  - Configurazione Flutter SDK 3.10.0+
  - Setup Gradle e dipendenze Android
  - Configurazione NDK e build tools
  
- [x] **Material Design 3 Expressive**
  - Implementato tema custom con primary color #6750A4
  - Dark mode nativo con ColorScheme dinamico
  - Typography e spacing MD3 compliant
  - Surface containers e elevation system

### 📦 Dipendenze Core
- [x] **Packages installati e configurati:**
  - `http: ^1.2.0` - Network requests
  - `webfeed_plus: ^1.1.2` - RSS parsing
  - `cached_network_image: ^3.3.1` - Image caching
  - `intl: ^0.19.0` - Internazionalizzazione
  - `url_launcher: ^6.2.5` - Apertura link esterni
  - `shared_preferences: ^2.2.2` - Storage locale
  - `flutter_custom_tabs: ^2.0.0+1` - Chrome Custom Tabs

### 🏠 Schermata Principale (Home)
- [x] **UI Components:**
  - SliverAppBar.large con floating/pinned
  - Pull-to-refresh per aggiornamento feed
  - Lista articoli con card animate
  - Shimmer loading states
  - Empty state con icone e messaggi
  - FAB per refresh manuale
  
- [x] **Card Notizie:**
  - Apertura diretta in Chrome Custom Tab al tocco
  - Badge sorgente colorato
  - Timestamp formattato (dd MMM yyyy • HH:mm)
  - Titolo, descrizione con ellipsis
  - CachedNetworkImage con placeholder/error
  - Navigazione rapida senza schermata intermedia

### 📡 Gestione Fonti RSS
- [x] **14 Fonti Italiane Android/Tech:**
  1. TuttoAndroid
  2. AndroidWorld (SmartWorld)
  3. HDblog Android
  4. Androidiani
  5. HDblog
  6. TecnoAndroid
  7. GizChina
  8. XiaomiToday
  9. Telefonino.net
  10. Tom's Hardware
  11. HWUpgrade
  12. EvoSmart
  13. DDay.it
  14. TuttoTech

- [x] **Parsing RSS Robusto:**
  - Timeout 15 secondi per feed lenti
  - Headers HTTP custom anti-blocco
  - Try-catch per singoli articoli
  - Gestione errori con logging
  - Fallback per date malformate
  - Pulizia HTML entities e caratteri speciali

- [x] **Estrazione Immagini:**
  - 4 metodi: media:content, enclosure, media:thumbnail, content:encoded
  - 3 pattern regex per HTML
  - Validazione URL immagini
  - Supporto Open Graph (og:image)
  - Cache ottimizzata con memCacheHeight

### 🎯 Filtri & Categorie
- [x] **Sistema Categorie Semplificato:**
  - Rimossi tab (Tutte/Generali/Tecnologia)
  - Visualizzazione unificata di tutte le fonti
  - Ordinamento per data (più recenti prima)

### 🌓 Dark Mode
- [x] **Theme Switching:**
  - Light theme con MD3 Expressive
  - Dark theme automatico
  - Transizioni smooth tra temi
  - Colori accessibili e contrast-compliant

### 🔧 Gestione Errori
- [x] **Error Handling Completo:**
  - Network errors con retry
  - Parsing errors con skip articolo
  - Image loading errors con placeholder
  - Snackbar notifiche utente
  - Logging console per debugging

---

## 🚧 In Sviluppo

### 📄 Schermata Dettaglio Articolo ✅ (Completato)
- [x] **UI Dettaglio:**
  - Hero animation da lista a dettaglio
  - SliverAppBar expandable con immagine
  - Gradient overlay per leggibilità
  - Contenuto completo articolo
  - Metadata (fonte, data, tempo lettura)
  
- [x] **Funzionalità:**
  - Apertura link originale in browser esterno
  - Copia link negli appunti
  - Toggle bookmark con persistenza SharedPreferences
  - Card "Leggi articolo completo"
  - Bottoni azioni rapide (Condividi, Salva, Copia)
  - Menu contestuale (Apri browser, Copia link)
  - Navigazione swipe tra articoli con PageView
  - Indicatore pagina corrente
  
- [x] **BookmarkService:**
  - Salvataggio/rimozione bookmark
  - Check stato bookmark per articolo
  - Recupero lista completa bookmark
  - Serializzazione JSON per persistenza
  - Contatore totale bookmark
  - Clear all bookmarks
  
- [x] **Chrome Custom Tabs:**
  - Apertura articoli in Custom Tab in-app
  - Transizioni fluide e native
  - Toolbar personalizzata con colore tema
  - Share button integrato
  - Nessun blocco X-Frame-Options/CORS
  - Fallback browser esterno disponibile
  
- [x] **Schermata Bookmark:**
  - BookmarksScreen con lista articoli salvati
  - Swipe-to-delete per rimozione rapida
  - Navigazione da HomeScreen AppBar
  - Empty state personalizzato
  - Pull-to-refresh
  - Clear all bookmarks con conferma
  - Navigazione verso dettaglio con swipe

### 🔍 Ricerca Notizie ✅ (Completato)
- [x] **Search Bar Animata:**
  - Icona search che si espande in barra di ricerca con AnimatedContainer
  - Animazione Material Design 3 Expressive (Curves.easeInOutCubicEmphasized)
  - TextField con bordi arrotondati (28px) e filled background
  - Filtro real-time su titoli/descrizioni durante digitazione
  - Pulsante close per chiudere ricerca
  - Empty state personalizzato per "nessun risultato"
  - Implementato in HomeScreen con state management locale
 [x] **Fase 2 Avanzata (23 Nov 2025):**
   - HighlightedText widget per evidenziare termini cercati nei risultati
   - SearchHistoryService con persistenza SharedPreferences (max 20 termini)
   - Autocomplete widget integrato nella search bar
   - Cronologia ricerche con icona clock e pulsante delete per ogni termine
   - Suggerimenti smart combinando history matches + estrazione parole da titoli
   - Dropdown suggerimenti con Material design e icone differenziate
   - Highlighting case-insensitive in titoli e descrizioni NewsCard
   - Clear button per pulire rapidamente il campo ricerca
   - Salvataggio automatico ricerche al submit (Enter o selezione)
   - Deduplicazione automatica suggerimenti

### ⭐ Sistema Preferiti ✅ (Completato)
- [x] **Bookmark Management (Fase 1):**
  - Save/unsave articoli con BookmarkService
  - BookmarksScreen dedicata con lista completa
  - Persistenza JSON con shared_preferences
  - Swipe to delete con dismissible
  - Toggle rapido da ArticleDetailScreen
  - Icona bookmark animata in AppBar
  - Clear all bookmarks con dialog conferma
  - Contatore totale bookmark
- [x] **Fase 2 Avanzata (28 Nov 2025):**
   - Badge contatore preferiti in HomeScreen (SliverAppBar) aggiornato realtime con ValueNotifier
   - Export preferiti in JSON (share_plus) e CSV (separatore ";")
   - Import preferiti da file JSON con validazione schema e merge evitando duplicati per `link`
   - Organizzazione in cartelle/tag (modello `BookmarkGroup {id, name, articleLinks}`)
   - Ricerca interna tra bookmark con HighlightedText per evidenziare titoli
   - Ordinamento configurabile (data aggiunta, fonte, titolo A→Z / Z→A)
   - Azioni bulk: selezione multipla con checkbox, rimozione gruppo, esportazione selezionati
   - UI gestione gruppi (BookmarkGroupsScreen) con crea/rinomina/elimina e conferme
   - BookmarkService con metodi per CRUD gruppi e gestione articoli per gruppo

### 📴 Gestione Offline ✅ (Completato)
- [x] **Offline-First (Fase 1):**
  - CacheService completo con shared_preferences e timestamp
  - Indicatore stato network con banner arancione in AppBar (realtime)
  - NetworkService con connectivity_plus per monitoraggio continuo stream
  - Sync automatico al ritorno online (aggiornamento background)
  - Storage limite configurabile (10-200 MB tramite slider in Settings)
  - Clear cache manuale con dialog conferma
  - Gestione automatica cache quando supera limite
  - FAB disabilitato quando offline
  - Caricamento intelligente da cache se valida (< 6 ore)
  - SettingsScreen con info cache (size, last update) e controlli
  - Cache articoli serializzata JSON con metadata
- [x] **Fase 2 Avanzata (28 Nov 2025):**
  - Preload intelligente: caching automatico dei 50 articoli più recenti per lettura offline prioritaria
  - Compressione GZIP della cache JSON: riduzione spazio ~60-70% con base64 encoding
  - Download immagini offline completo: CachedNetworkImage con maxHeightDiskCache per persistent storage
  - Supporto fallback compatibilità: decompressione graceful per cache legacy non compressa
  - Preload automatico in background quando si caricano nuovi articoli online

### ✨ Animazioni & Transizioni ✅ (Completato)
- [x] **Motion Design (Fase 1):**
  - Hero animations complete per immagini articoli (lista → dettaglio)
  - Page transitions custom (slide, fade, scale, shared axis) con MD3 Expressive
  - Card entrance animations staggered con TweenAnimationBuilder e delay progressivo
  - Shimmer loading avanzato con gradient animato pulsante e skeleton screens
  - Micro-interactions sui tap: scale animation 0.97x con GestureDetector
  - Animazioni fluide con Curves.easeInOutCubicEmphasized (MD3 standard)
  - Durata ottimizzata (300-400ms) per feel responsive
  - PageTransitions utility con 5 tipi di transizioni riutilizzabili
  - Search bar expand/collapse animation smooth
  - FAB show/hide animation quando offline
  - Bookmark icon animation (filled/outlined)

- [x] **Fase 2 - Advanced Effects (Completato 8 Dicembre 2025):**
  - **Parallax Scroll Effects:** Implementato in ArticleDetailScreen con ScrollController e Transform.translate
    - Effetto parallax sulla immagine dell'articolo durante lo scroll
    - Fattore parallax 0.5x per movimento fluido
    - Widget custom _ParallaxImage con CachedNetworkImage
    - Integrato in FlexibleSpaceBar con stretchModes
  - **Lottie Animations:** Aggiunte animazioni JSON per empty states
    - empty_articles.json: Animazione pallini per feed vuoto (HomeScreen)
    - empty_bookmarks.json: Animazione bookmark per nessun bookmark (BookmarksScreen)
    - no_search_results.json: Animazione search per risultati vuoti (HomeScreen, BookmarksScreen)
    - Dimensioni responsive (150-200px) e colori tema-coerenti
  - **Haptic Feedback:** Feedback tattile su interazioni critiche
    - HapticFeedback.lightImpact() su selezione articoli singoli
    - HapticFeedback.mediumImpact() su toggle bookmark e selezione massiva
    - HapticFeedback.heavyImpact() su eliminazione bulk
    - Integrato in _toggleBookmark, _deleteSelected, _toggleArticleSelection, _toggleSelectionMode

---

### 🎛️ Personalizzazione UI ✅ (Completato)
- [x] **SourcesSettingsScreen:**
  - Selezione fonti preferite (abilita/disabilita toggle per ciascuna)
  - Riordino fonti con drag & drop (ReorderableListView)
  - Salvataggio preferenze persistente con SettingsService
  - Preview contatore fonti attive
- [x] **SettingsScreen Completo:**
  - Layout griglia/lista commutabile con toggle switch
  - Dimensione testo configurabile (90%–130%) con slider e preview live
  - Tema selezionabile (Sistema/Chiaro/Scuro) con RadioListTile
  - Link a SourcesSettingsScreen e ThemeCustomizationScreen
  - Info cache (size, limite, ultimo aggiornamento)
  - Clear cache con conferma dialog
  - Slider limite cache (10-200 MB) dinamico
- [x] **Applicazione Globale:**
  - SettingsService con ValueNotifier per reactive updates
  - Rebuilding automatico UI su cambio impostazioni
  - Persistenza con SharedPreferences

---

## 🔮 Funzionalità Future (Roadmap 2026)

### 📱 Esperienza Utente Avanzata
  
- [ ] **Smart Reading:**
  - Reading progress indicator per articoli lunghi
  - "Continue reading" per articoli interrotti
  - Reading time estimation
  - Text-to-Speech per lettura vocale
  - Font size per-article override
  - Night reading mode (sepia/dark)

### 🌐 Multi-lingua ✅ (Completato)
- [x] **Internazionalizzazione:**
  - Supporto English/Italiano con flutter_localizations
  - Traduzioni UI complete tramite ARB files (app_en.arb, app_it.arb)
  - Configurazione l10n.yaml per codegen automatico
  - AppLocalizations delegate integrato in MaterialApp
  - Supporto automatico per date localizzate (via intl 0.20.2)
  - 60+ stringhe tradotte per interfaccia completa
  - Traduzione di tutte le schermate (Home, Settings, Bookmarks, Detail)
  - Messaggi errore e dialog localizzati
  - Formattazione date/orari locale-aware
- [ ] **Da aggiungere (fase 2):**
  - Supporto lingue aggiuntive (ES, FR, DE)
  - Traduzione automatica note release
  - RTL support per lingue arabe

  
### 🎨 Temi Avanzati ✅ (Completato)
- [x] **ThemeCustomizationScreen Completo:**
  - Schermata dedicata navigabile da Settings
  - 5 preset temi predefiniti bellissimi:
    - Default (Purple #6750A4)
    - Ocean (Blue #0277BD)
    - Forest (Green #2E7D32)
    - Sunset (Orange #E64A19)
    - Purple (Deep Purple #7B1FA2)
  - Modalità Custom con selezione colori libera
  - Color picker HSL avanzato con sliders (Hue, Saturation, Lightness)
  - Preset colors quick-select per scelte rapide
  - Selezione separata Primary e Secondary color
  - True Black Mode toggle per OLED (sfondo #000000)
  - Preview cards live per vedere effetto immediato
  - Persistenza completa con SharedPreferences
  - ThemeCustomizationService con ValueNotifier per reactive UI
  - ColorScheme.fromSeed() dinamico con Material Design 3
  - Integrazione seamless con AppTheme principale
  - Apply/Reset buttons per conferma modifiche
- [ ] **Da aggiungere (fase 2):**
  - Import/Export temi personalizzati (JSON)
  - Community themes repository
  - Gradient backgrounds opzionali
  - Custom font selection
### 📊 Analytics & Stats
- [ ] **Statistiche Utente:**
  - Articoli letti
  - Fonti più lette
  - Tempo lettura totale
  - Grafici mensili
  - Streak giorni consecutivi

### 💾 Database Locale
- [ ] **Migrazione a SQLite:**
  - Database strutturato
  - Query ottimizzate
  - Full-text search
  - Relazioni articoli-fonti-tag
  - Migration system

### 🔐 Privacy & Sicurezza
- [ ] **Features Privacy:**
  - HTTPS only
  - No tracking analytics
  - Clear history/cache
  - Privacy policy integrata
  - Export dati utente (GDPR)

### 🤖 AI Features
- [ ] **Intelligenza Artificiale:**
  - Riassunti automatici articoli
  - Suggerimenti personalizzati
  - Sentiment analysis
  - Topic clustering
  - Smart notifications

### 🔄 Sync Cloud
- [ ] **Cloud Sync:**
  - Account utente
  - Sync preferiti multi-device
  - Backup cloud articoli salvati
  - Reading progress sync

---

## 📝 Note Tecniche

### 🏗️ Architettura Attuale
```
lib/
├── main.dart                      # Entry point + MaterialApp
├── models/
│   └── news_article.dart         # Model dati articolo
├── services/
│   └── rss_service.dart          # Fetching RSS feeds
├── screens/
│   ├── home_screen.dart          # Schermata principale
│   └── article_detail_screen.dart # Dettaglio articolo
└── theme/
    └── app_theme.dart            # Material Design 3 theme
```

### 🛠️ Stack Tecnologico
- **Framework:** Flutter 3.10.0+
- **Linguaggio:** Dart 3.10.0+
- **State Management:** StatefulWidget (base)
- **Networking:** http package
- **RSS Parsing:** webfeed_plus
- **Image Caching:** cached_network_image
- **Storage:** shared_preferences

### 🔧 Miglioramenti Tecnici Pianificati
- [ ] Implementare Provider/Riverpod per state management
- [ ] Unit tests per RssService
- [ ] Widget tests per HomeScreen
- [ ] Integration tests end-to-end
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Code coverage >80%
- [ ] Performance profiling
- [ ] Memory leak detection

### 📊 Metriche Performance Target
- [ ] Startup time < 2s
- [ ] RSS fetch < 5s (per fonte)
- [ ] Scroll 60fps constante
- [ ] Memory usage < 150MB
- [ ] APK size < 25MB

---

## 🐛 Bug Noti & Fix Pianificati
- [x] ~~Errori parsing RSS con feed malformati~~ (RISOLTO)
- [x] ~~Crash su immagini non valide~~ (RISOLTO)
- [x] ~~Caratteri HTML entities nelle card~~ (RISOLTO)
- [x] ~~Performance su liste molto lunghe (lazy loading)~~ (RISOLTO - 19 Dic 2025)
  - Implementato ListView con paginazione infinita (20 articoli per pagina)
  - Caricamento automatico all'80% dello scroll
  - Indicatore di caricamento durante infinite scroll
- [x] ~~Gestione rotazione schermo (state preservation)~~ (RISOLTO - 19 Dic 2025)
  - Aggiunto AutomaticKeepAliveClientMixin su HomeScreen, ArticleDetailScreen, BookmarksScreen
  - Preservazione dello stato durante rotazione dello schermo
- [x] ~~Deep links non implementati~~ (RISOLTO - 19 Dic 2025)
  - Aggiunta integrazione go_router per gestione routing
  - Configurati intent filters per android_news:// scheme
  - Supporto App Links per https://androidnews.app/article/{id}
- [x] ~~Errore immagine splash screen~~ (RISOLTO - 21 Dic 2025)
  - Rigenerata app_icon.png con script generate_assets.py
  - Ottimizzata dimensione icona 256x256 per splash screen
  - Icona validata e funzionante in AnimatedSplashScreen

---

## 📅 Milestone

### v0.1.0 - MVP ✅ (Completato - 17 Nov 2025)
- Setup progetto
- Fetching RSS da 14 fonti italiane
- Lista articoli con card MD3
- Dark mode
- Pull-to-refresh

### v0.2.0 - Funzionalità Base ✅ (Completato - 23 Nov 2025)
- ✅ Schermata dettaglio articolo completa
- ✅ Ricerca articoli real-time
- ✅ Sistema preferiti con persistenza BookmarkService
- ✅ Gestione offline completa con CacheService
- ✅ SettingsScreen con personalizzazione completa
- ✅ ThemeCustomizationScreen con preset e custom colors
- ✅ SourcesSettingsScreen con drag & drop
- ✅ Multi-lingua EN/IT
- ✅ Animazioni MD3 Expressive complete

### v0.3.0 - Advanced Features ✅ (Completato - 19 Dic 2025)
- [x] Lazy loading per liste lunghe (paginazione infinita)
- [x] State preservation rotazione schermo (AutomaticKeepAlive)
- [x] Deep links e App Links (android_news://, https://)
- [x] go_router per navigazione avanzata

### v0.3.1 - Performance Optimizations ✅ (Completato - 19 Dic 2025)
- [x] Impeller rendering engine abilitato
- [x] Image compression on-the-fly (flutter_image_compress)
- [x] WebP/AVIF support per immagini moderne
- [x] Lazy initialization services (critical vs non-critical)
- [x] Memory profiling e leak detection
- [x] Startup time ottimizzato < 1s

### v0.4.0 - Monetization & Ads 🚧 (Prossima - Q1 2026)
- [ ] AdMob integration (banner ads)
- [ ] In-app purchases (Play Billing v6+)
- [ ] Paywall soft gate
- [ ] Premium features

### v0.3.2 - Background Sync ✅ (Completato - 20 Dic 2025)
- [x] WorkManager integration per sync periodico
- [x] Foreground service per download articoli
- [x] Background fetch delle immagini
- [x] Smart refresh basato su usage patterns
- [x] Sync intelligente con battery optimization
- [x] Breaking news notifications automatiche
- [x] BackgroundSyncSettingsScreen completa
- [x] Statistiche sync in tempo reale
- [x] Sync manuale on-demand
- [x] Image preloading in background
- [x] Test suite completa per BackgroundSyncService

---

## 🤝 Contributi
Questo è un progetto in evoluzione. Le feature vengono implementate progressivamente seguendo questa roadmap.

## 📄 License
Progetto personale - Android News App

---

## 🆕 Nuove Funzionalità Moderne (Ottobre 2025+)

### 🤖 AI & Machine Learning
- [ ] **Gemini API Integration:**
  - Riassunti articoli automatici con Google Gemini
  - Traduzioni articoli in altre lingue
  - Q&A su articoli: "Chiedi all'AI"
  - Sentiment analysis per classificare notizie
  - Tag automatici con AI
  
- [ ] **Raccomandazioni Intelligenti:**
  - Feed personalizzato basato su letture precedenti
  - "Simili a questo" per ogni articolo
  - Topic clustering automatico
  - Smart notifications (solo notizie rilevanti)

### 📱 Material Design 3 Adaptive (2025)
- [x] **Dynamic Color System:**
  - [x] Material You dynamic colors da wallpaper Android 12+
  - [x] Adaptive icons con themed icons support
  - [x] Predictive back gesture (Android 14)
  - [x] Edge-to-edge layout (draw behind system bars)
  
- [ ] **Responsive Design:**
  - Large screen layouts (tablet/foldable)
  - Adaptive navigation (rail per tablet)
  - Multi-column layout per schermi grandi
  - Picture-in-Picture per video embeddati

### 🔔 Notifiche & Background
- [x] **Push Notifications:**
  - [x] Firebase Cloud Messaging
  - [x] Notifiche per fonti preferite
  - [x] Notifiche breaking news
  - [x] Rich notifications con immagini
  - [x] Actions dirette (Leggi, Salva, Condividi)
  - [x] Notification channels personalizzati
  
- [x] **Background Sync:** ✅ (Completato - 20 Dic 2025)
  - [x] WorkManager per sync periodico
  - [x] Foreground service per download articoli
  - [x] Background fetch delle immagini
  - [x] Smart refresh basato su usage patterns
  - [x] Sync intelligente con battery optimization
  - [x] Statistiche sync e analytics
  - [x] UI controlli personalizzazione sync
  - [x] Notifiche breaking news automatiche

### 🏠 Widgets & Shortcuts
- [ ] **Home Screen Widgets:**
  - Widget lista ultime notizie (small/medium/large)
  - Widget articolo singolo featured
  - Glanceable widget Material 3
  - Interactive widget (Android 12+)
  - Widget configuration per fonte preferita
  
- [ ] **App Shortcuts:**
  - Static shortcuts (Bookmarks, Ricerca)
  - Dynamic shortcuts (Articoli recenti)
  - Pinned shortcuts per fonti favorite
  - App Actions per Google Assistant

### 🔗 Sharing & Deep Links
- [ ] **Enhanced Sharing:**
  - Share sheet custom con preview
  - Share target per ricevere link esterni
  - Direct share ai contatti frequenti
  - Screenshot articolo per social
  - Copy link with preview metadata
  
- [ ] **Deep Links:**
  - App Links verified per android_news://
  - Open da browser: android-news.app/article/{id}
  - Intent filters per gestire link notizie
  - Universal links per cross-platform

### 📊 Analytics Privacy-First
- [ ] **Local Analytics:**
  - Statistiche lettura locali (no server)
  - Dashboard utilizzo app
  - Grafici articoli letti per giorno/settimana/mese
  - Top fonti più lette
  - Reading streak counter
  - Export dati utente (GDPR compliant)

### 🎮 Gamification
- [ ] **Achievements & Badges:**
  - Badge per milestone (10/50/100 articoli)
  - Streak badges (lettura giornaliera)
  - Explorer badges (nuove fonti)
  - Collector badges (bookmark milestones)
  - Achievements screen con unlock progressivi

### 🔐 Privacy & Security (2025)
- [ ] **Privacy Enhanced:**
  - Privacy Dashboard (iOS-style)
  - Tracking transparency report
  - HTTPS-only strict mode
  - Certificate pinning per API
  - Biometric lock per app (opzionale)
  - Secure storage per bookmark sensibili
  - Data deletion tool (forget me)

### ⚡ Performance & Optimization ✅ (Completato - 19 Dic 2025)
- [x] **Performance 2025:**
  - [x] Impeller rendering engine abilitato (Flutter 3.16+)
  - [x] Incremental list loading (pagination) - implementato lazy loading
  - [x] Image compression on-the-fly - ImageOptimizationService
  - [x] WebP/AVIF support per immagini moderne - header Accept-Image
  - [x] Code splitting per ridurre bundle size - lazy initialization services
  - [x] Lazy loading screens - non-critical services in background
  - [x] Memory leak detection con DevTools - PerformanceMonitoringService
  - [x] Startup time < 1s target - ottimizzazione critical vs non-critical services

### 🧪 Testing & Quality (2025)
- [ ] **Modern Testing:**
  - Integration tests con Patrol
  - Golden tests per UI regression
  - Performance tests con benchmarks
  - Accessibility tests (TalkBack/VoiceOver)
  - Screenshot tests multi-device
  - CI/CD con GitHub Actions
  - Automated Play Store deployment

### 🌍 Multi-Platform (Future)
- [ ] **Cross-Platform Expansion:**
  - iOS app completa
  - Web app PWA responsive
  - Desktop apps (Windows/macOS/Linux)
  - Sync cloud multi-device
  - Universal account system

---

**Ultima modifica:** 20 dicembre 2025  
**Versione Roadmap:** 2.4  
**Status Progetto:** v0.2.0 completata ✅ | v0.3.0 completata ✅ | v0.3.1 performance optimizations ✅ | v0.3.2 Background Sync ✅ | Push Notifications con Firebase ✅ | v0.4.0 Monetization in pianificazione 🚧
