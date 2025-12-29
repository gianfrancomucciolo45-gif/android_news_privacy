# Playwright Automation - Play Console & App Links

Automazione completa per:
1. **Play Console:** Configurazione store listing, pricing, content
2. **App Links:** Setup DNS, GitHub Pages, verifica domini

## Requisiti
- Node.js 18+
- Accesso alla Play Console con 2FA

## Setup
1. Installa dipendenze e browser
```
cd "tools/playwright"
npm install
npm run prep
```
2. Crea il file `.env` a partire da `.env.example` e personalizza i campi (titoli, descrizioni, contatti, paesi).

## Login (interattivo, One-time)
```
npm run login
```
- Si aprirà Play Console: esegui login manuale (2FA). Al termine, lo script salverà `auth/state.json` per le esecuzioni successive.

## Esecuzione script
- Scheda Store (titolo/descrizioni/categoria/contatti):
```
npm run listing
```
- Prezzi e Distribuzione (gratuita, paesi):
```
npm run pricing
```
- App Content (accesso, pubblicità, target audience):
```
npm run content
```
- Eseguire tutto in sequenza:
```
npm run all
```

## Note importanti
- La Play Console cambia UI frequentemente. Gli script usano selettori robusti, ma potresti dover ritoccare alcuni passaggi.
- I questionari **Content rating** e **Data safety** sono intenzionalmente non automatizzati perché dipendono da risposte legali/di conformità variabili. Compilali manualmente dopo aver eseguito `npm run content`.
- Per selezionare l'app, lo script usa per default il titolo (`APP_NAME`). In alternativa, imposta `SELECT_BY=package` e `PACKAGE_NAME` nel `.env`.
- Assicurati di avere pronti gli asset (icone, screenshot, feature graphic). L'upload automatico non è incluso qui per evitare errori di formati/dimensioni, ma può essere aggiunto se necessario.

## Variabili `.env`
- `APP_NAME`: titolo app (es. "Android News")
- `DEFAULT_LOCALE`: lingua default (es. `it-IT`)
- `SHORT_DESCRIPTION`, `FULL_DESCRIPTION`: testi store
- `CATEGORY`: categoria (es. "News & Magazines")
- `EMAIL_CONTACT`, `WEBSITE`, `PRIVACY_URL`: contatti e privacy
- `COUNTRIES`: elenco paesi separati da virgola (es. `IT,SM,VA`)
- `PRICING_FREE`: `true`/`false`
- `SELECT_BY`: `title` o `package`
- `PACKAGE_NAME`: necessario se `SELECT_BY=package`

## App Links Setup (NUOVO)

### Quick Start Automatico

```bash
cd ../..  # Torna alla root del progetto
./tools/setup-app-links-complete.sh
```

Lo script orchestratore esegue tutto automaticamente:
1. Verifica prerequisiti
2. Controlla/attende propagazione DNS
3. Configura GitHub Pages (custom domain + HTTPS)
4. Verifica endpoint assetlinks.json
5. Esegue recheck su Play Console

### Test Individuali

```bash
# Configura GitHub Pages
npx playwright test src/configure-github-pages.spec.ts --headed

# Recheck Play Console
npx playwright test src/verify-app-links.spec.ts --headed --grep "Recheck"
```

### Prerequisiti App Links

1. **DNS configurato** (vedi [../../docs/DNS_SETUP.md](../../docs/DNS_SETUP.md)):
   ```
   Type: A  @  185.199.108.153
   Type: A  @  185.199.109.153
   Type: A  @  185.199.110.153
   Type: A  @  185.199.111.153
   ```

2. **GitHub Token** (opzionale, per automazione completa):
   ```bash
   export GITHUB_TOKEN=ghp_your_token_here
   ```

3. **Verifica script:**
   ```bash
   ../../tools/check_dns.sh
   ../../tools/check_assetlinks.sh
   ```

### Output Atteso

✅ DNS configurato  
✅ GitHub Pages custom domain: androidnews.app  
✅ HTTPS enforced  
✅ Endpoint https://androidnews.app/.well-known/assetlinks.json → 200 OK  
✅ Play Console App Links verificati  

## Troubleshooting

### Play Console
- Se dopo il login non viene salvato lo stato: ripeti `npm run login` e attendi di vedere la pagina "Tutte le app".
- Selezioni non trovate: aumenta i timeout o aggiorna i selettori testuali in `src/utils.ts`.
- Per esecuzioni headless: imposta `headless: true` negli script (consigliato interattivo per la Play Console).

### App Links
- **DNS non propagato:** Verifica con `dig @8.8.8.8 androidnews.app`, attendi 5-30 min
- **Certificato SSL non pronto:** Normale per domini nuovi, attendi 10-20 min
- **Endpoint 404:** Verifica HTTPS attivo e .nojekyll presente (già nel repo)
- **Test timeout:** Aumenta timeout in `playwright.config.ts` a 300000 (5 min)

## Documentazione Completa

- App Links Setup: [../../QUICK_START.md](../../QUICK_START.md)
- DNS Configuration: [../../docs/DNS_SETUP.md](../../docs/DNS_SETUP.md)
- Email Notifications: [../../docs/NOTIFICATIONS_SETUP.md](../../docs/NOTIFICATIONS_SETUP.md)
