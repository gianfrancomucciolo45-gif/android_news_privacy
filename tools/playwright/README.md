# Play Console Automation (Playwright)

Automazione semi-assistita per completare la configurazione dell'app su Google Play Console.

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

## Troubleshooting
- Se dopo il login non viene salvato lo stato: ripeti `npm run login` e attendi di vedere la pagina "Tutte le app".
- Selezioni non trovate: aumenta i timeout o aggiorna i selettori testuali in `src/utils.ts`.
- Per esecuzioni headless: imposta `headless: true` negli script (consigliato interattivo per la Play Console).
