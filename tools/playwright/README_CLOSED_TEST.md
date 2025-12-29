# Automazione Closed Testing (Play Console)

Questo modulo usa Playwright per assistere la creazione di una release su traccia di **Test chiuso**.

## Limiti
- La UI di Google Play Console cambia spesso: selettori fragili.
- Autenticazione Google + 2FA non può essere completamente automatizzata; login iniziale manuale.
- Upload AAB: se l'input file è incapsulato in componente custom potrebbe servire intervento manuale.

## Prerequisiti
1. Node 18+ installato.
2. `cd tools/playwright`
3. Installare dipendenze + browser: `npm install && npm run prep`
4. Generare build firmata AAB: `flutter build appbundle --release` (il file atteso: `build/app/outputs/bundle/release/app-release.aab`).
5. Impostare variabili in `.env` (vedi `.env.example`). Campi rilevanti:
   - `APP_NAME=Android News`
   - `PACKAGE_NAME=com.mucciologianfranco.android_news`
   - `RELEASE_NOTES=Prima build di test chiuso`
   - `TESTERS_EMAILS=email1@example.com,email2@example.com`
   - `AAB_PATH=../../build/app/outputs/bundle/release/app-release.aab`

## Passi
### 1. Login e salvataggio sessione
```bash
npm run login
```
Attendi apertura Chrome, effettua login e 2FA. Al termine il file `auth/state.json` verrà salvato.

### 2. Esecuzione test di creazione release closed
```bash
npx playwright test src/closed-test-release.spec.ts --project=chromium --headed
```
Il test tenterà di:
1. Aprire l'app.
2. Navigare alla sezione Closed Testing.
3. Creare nuova release.
4. Caricare AAB.
5. Inserire note di rilascio.
6. Aggiungere tester (se specificati).
7. Inviare la release.

### 3. Verifica
Al termine dovresti vedere un indicatore di stato (release inviata / pending review). In caso di fallimento, apri Play Console e completa manualmente.

## Suggerimenti Robustezza
- Se il selettore per Closed Testing non funziona, modifica la funzione `gotoClosedTesting` nel file `src/closed-test-release.spec.ts`.
- Aumenta timeout se la rete è lenta (`test.setTimeout`).

## Sicurezza
- Non committare credenziali Google.
- `auth/state.json` contiene cookie/sessione: aggiungi a `.gitignore` se non già escluso.

## Aggiornamenti Futuri
- Integrazione Play Developer API per creare release senza UI.
- Gestione graduale dei fallback UI.

---
Se servono aggiustamenti ai selettori, indicami l'errore specifico e li raffinerò.
