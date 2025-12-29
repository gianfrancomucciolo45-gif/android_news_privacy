# DNS Setup per androidnews.app

Questa guida spiega come configurare i record DNS per far funzionare il custom domain con GitHub Pages.

## Record DNS Richiesti

### 1. Record A per apex domain (androidnews.app)

Aggiungi **4 record A** che puntano agli IP di GitHub Pages:

```
Type: A
Name: @ (o androidnews.app)
Value: 185.199.108.153
TTL: 3600 (o automatico)

Type: A
Name: @ (o androidnews.app)
Value: 185.199.109.153
TTL: 3600

Type: A
Name: @ (o androidnews.app)
Value: 185.199.110.153
TTL: 3600

Type: A
Name: @ (o androidnews.app)
Value: 185.199.111.153
TTL: 3600
```

### 2. Record CNAME per www (Opzionale ma Raccomandato)

```
Type: CNAME
Name: www
Value: gianfrancomucciolo45-gif.github.io
TTL: 3600
```

## Provider DNS Comuni

### Namecheap
1. Accedi a Namecheap Dashboard
2. Domain List → Manage per androidnews.app
3. Advanced DNS tab
4. Add New Record per ogni record A
5. Save All Changes

### GoDaddy
1. My Products → DNS
2. Seleziona androidnews.app
3. Add per ogni record (Type: A, Name: @, Value: IP)
4. Save

### Cloudflare
1. Dashboard → DNS
2. Seleziona androidnews.app
3. Add record (Type: A, Name: @, IPv4: IP, Proxy: OFF per GitHub Pages)
4. Ripeti per tutti e 4 gli IP
5. CNAME: www → gianfrancomucciolo45-gif.github.io (Proxy: OFF)

**IMPORTANTE:** Disabilita proxy Cloudflare (cloud grigio) per i record GitHub Pages, altrimenti la verifica App Links potrebbe fallire.

### Google Domains / Squarespace
1. DNS Settings
2. Custom records
3. Aggiungi record A con host "@" e i 4 IP
4. CNAME con host "www" e valore gianfrancomucciolo45-gif.github.io

## Verifica Configurazione DNS

Dopo aver configurato i record, verifica con:

```bash
# Verifica record A
dig androidnews.app +short

# Dovrebbe mostrare:
# 185.199.108.153
# 185.199.109.153
# 185.199.110.153
# 185.199.111.153

# Verifica CNAME www
dig www.androidnews.app +short

# Dovrebbe mostrare:
# gianfrancomucciolo45-gif.github.io.
# 185.199.108.153
# ...

# Oppure usa lo script di verifica:
./tools/check_dns.sh
```

## Propagazione DNS

⏱️ **Tempo di propagazione:** 5 minuti - 48 ore (tipicamente 15-30 minuti)

Puoi monitorare la propagazione su:
- https://dnschecker.org
- https://www.whatsmydns.net

Inserisci `androidnews.app` e verifica che i 4 IP siano visibili da server DNS globali.

## GitHub Pages Configuration

Dopo che i DNS sono propagati:

1. **Repository Settings:**
   - Vai su https://github.com/gianfrancomucciolo45-gif/android_news_privacy/settings/pages
   - In "Custom domain" inserisci: `androidnews.app`
   - Click "Save"
   - Attendi qualche minuto per la verifica DNS

2. **Enforce HTTPS:**
   - Una volta che il certificato SSL è pronto (di solito entro 10-15 minuti)
   - Spunta "Enforce HTTPS"
   - Click "Save"

3. **Verifica finale:**
   ```bash
   curl -I https://androidnews.app/.well-known/assetlinks.json
   # Deve rispondere 200 OK con Content-Type: application/json
   ```

## Troubleshooting

### DNS non si propaga
- Verifica che i record siano stati salvati correttamente nel pannello DNS
- Usa `dig @8.8.8.8 androidnews.app` per interrogare direttamente Google DNS
- Controlla TTL: se troppo alto, riduci a 300-600 secondi per modifiche veloci

### GitHub Pages non riconosce il dominio
- Verifica che il file `CNAME` nel repo contenga `androidnews.app` (già presente)
- Controlla che i record A puntino ESATTAMENTE agli IP GitHub (nessun proxy intermediario)
- Rimuovi e ri-aggiungi il custom domain nelle impostazioni Pages

### Certificato SSL non si genera
- Aspetta 15-30 minuti dopo la verifica DNS
- Rimuovi e ri-aggiungi il custom domain per forzare nuova richiesta certificato
- Verifica CAA record DNS non blocchino Let's Encrypt (se presenti)

### App Links verification fallisce
- Assicurati che `/.well-known/assetlinks.json` sia accessibile via HTTPS
- Verifica Content-Type sia `application/json` (non `text/plain`)
- Controlla che non ci siano redirect (301/302) prima del JSON
- Usa lo script di check: `./tools/check_assetlinks.sh`

## Monitoraggio Automatico

Il workflow GitHub Actions monitora l'endpoint ogni 15 minuti e ti notificherà:
- **GitHub Issue:** Quando l'endpoint diventa disponibile e valido
- **Email (opzionale):** Se hai configurato i segreti SMTP

Workflow path: `.github/workflows/monitor-assetlinks.yml`

## Prossimi Passi

Dopo che DNS è OK e HTTPS attivo:

1. ✅ Verifica endpoint: `https://androidnews.app/.well-known/assetlinks.json`
2. ✅ Monitora workflow per conferma automatica
3. 🎯 **Play Console:** Collegamenti app → Ricontrolla la verifica per `androidnews.app`
4. 🎉 Verifica completata!

---

**Nota:** Questo setup è per GitHub Pages. Se usi un altro hosting (Netlify, Vercel, etc.) i record DNS potrebbero differire.

**Ultimo aggiornamento:** 29 Dicembre 2025
