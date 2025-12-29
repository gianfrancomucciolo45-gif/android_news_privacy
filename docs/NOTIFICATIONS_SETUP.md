## Notifiche monitor endpoint AssetLinks

Il workflow `Monitor AssetLinks Endpoint` invia:
- un'Issue GitHub quando l'endpoint diventa OK;
- (opzionale) un'email, se sono configurati i secrets SMTP.

### Configurare invio email

Secrets richiesti (Settings → Secrets and variables → Actions):
- `SMTP_HOST` (es. `smtp.mail.yahoo.com`)
- `SMTP_PORT` (es. `465` per SSL o `587` per STARTTLS)
- `SMTP_USERNAME` (di solito l'email)
- `SMTP_PASSWORD` (consigliata app password dedicata)
- `SMTP_FROM` (mittente, es. `gmucciolo85@yahoo.it`)

Per Yahoo Mail tipicamente:
- Host: `smtp.mail.yahoo.com`
- Port: `465`
- Username: il tuo indirizzo Yahoo
- Password: app password (attiva in sicurezza account)

### Configurazione rapida con GitHub CLI

1) Installa `gh`: https://cli.github.com/
2) Autenticati:

```bash
gh auth login
```

3) Esegui lo script helper e segui i prompt:

```bash
bash tools/set_smtp_secrets.sh
```

Inserisci `owner/repo` (es: `gianfrancomucciolo45-gif/android_news_privacy`) e i valori SMTP.

### Verifica
- Avvia manualmente il workflow da Actions → `Monitor AssetLinks Endpoint` → `Run workflow`.
- Al primo esito positivo verrà inviata l'email e creata un'Issue.
