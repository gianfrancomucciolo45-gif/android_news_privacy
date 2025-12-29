# 🚀 Guida Rapida: Configurazione Dominio androidnews.app

## Stato Attuale ✅

- [x] Repository configurato con CNAME
- [x] File assetlinks.json pronto
- [x] Workflow monitoraggio attivo
- [x] Script di verifica creati
- [ ] **DNS da configurare** ← PROSSIMO PASSO
- [ ] GitHub Pages custom domain da abilitare
- [ ] HTTPS da attivare

## 📋 Cosa Fare Ora (3 Passi)

### Passo 1: Configurare DNS ⚙️

Accedi al pannello DNS del tuo provider (Namecheap, GoDaddy, Cloudflare, etc.) e:

**Rimuovi** i record A attuali che puntano a:
- `15.197.142.173`
- `3.33.152.147`

**Aggiungi** questi 4 record A per GitHub Pages:

```
Type: A    Name: @    Value: 185.199.108.153    TTL: 3600
Type: A    Name: @    Value: 185.199.109.153    TTL: 3600
Type: A    Name: @    Value: 185.199.110.153    TTL: 3600
Type: A    Name: @    Value: 185.199.111.153    TTL: 3600
```

**Opzionale** - Aggiungi CNAME per www:
```
Type: CNAME    Name: www    Value: gianfrancomucciolo45-gif.github.io    TTL: 3600
```

**IMPORTANTE per Cloudflare:** Disattiva il proxy (cloud grigio ☁️ → nuvola grigia)

📖 **Guida completa:** Vedi [docs/DNS_SETUP.md](docs/DNS_SETUP.md)

**Verifica locale:** Dopo 5-15 minuti dalla modifica DNS, esegui:
```bash
./tools/check_dns.sh
```

Attendi finché lo script mostra "✅ DNS is ready!"

---

### Passo 2: Configurare GitHub Pages 🌐

Quando DNS è OK (check_dns.sh mostra ✅):

1. **Apri GitHub Pages Settings:**
   ```
   https://github.com/gianfrancomucciolo45-gif/android_news_privacy/settings/pages
   ```

2. **Custom domain:**
   - Campo "Custom domain": inserisci `androidnews.app`
   - Click **Save**
   - Attendi verifica DNS (1-5 minuti)
   - Apparirà checkmark verde ✅ quando pronto

3. **Enforce HTTPS:**
   - GitHub richiederà automaticamente certificato SSL Let's Encrypt
   - Dopo 10-20 minuti, il checkbox "Enforce HTTPS" diventerà selezionabile
   - **Spuntalo** e salva

**Helper interattivo:**
```bash
./tools/setup_github_pages.sh
```

**Verifica endpoint:** Una volta HTTPS attivo:
```bash
./tools/check_assetlinks.sh
```

Deve mostrare:
```
✅ Status: 200
✅ Content-Type: application/json
✅ OK: endpoint is valid with expected package, fingerprint and content-type
```

---

### Passo 3: Ricontrollare Verifica su Play Console 🎯

Quando l'endpoint è OK (check_assetlinks.sh mostra ✅):

1. **Apri Play Console:**
   ```
   https://play.google.com/console → App integrity → App links
   ```

2. **Trova androidnews.app** nella lista domini

3. **Click "Ricontrolla la verifica"** (o "Recheck verification")

4. **Attendi** qualche minuto per il risultato

5. ✅ **Verifica completata!**

---

## 🔄 Monitoraggio Automatico

Il workflow GitHub Actions controlla l'endpoint ogni 15 minuti e ti notifica:

- **GitHub Issue:** Creata automaticamente quando endpoint OK
- **Email (opzionale):** Inviata a gmucciolo85@yahoo.it se configuri SMTP secrets

**Configurare email (opzionale):**
```bash
./tools/set_smtp_secrets.sh
```

---

## 📞 Aiuto

### DNS non si aggiorna?
- TTL troppo alto? Riduci a 300 secondi
- Svuota cache DNS locale: `sudo systemd-resolve --flush-caches`
- Verifica con: `dig @8.8.8.8 androidnews.app`

### GitHub Pages non riconosce dominio?
- Verifica DNS sia OK con `./tools/check_dns.sh`
- Aspetta 5-10 minuti dopo salvataggio DNS
- Rimuovi e ri-aggiungi custom domain nelle impostazioni

### Certificato SSL non si genera?
- Aspetta 15-30 minuti (normale)
- Rimuovi e ri-aggiungi dominio per forzare nuova richiesta
- Verifica non ci siano CAA record che bloccano Let's Encrypt

### Verifica Play Console fallisce?
- Conferma endpoint OK: `./tools/check_assetlinks.sh`
- Verifica Content-Type sia `application/json`
- Controlla non ci siano redirect prima del JSON
- Riprova dopo qualche ora (cache Play Console)

---

## 🎯 Checklist Finale

Prima di fare "Ricontrolla verifica":

- [ ] DNS configurato (4 record A GitHub Pages)
- [ ] `./tools/check_dns.sh` → ✅ DNS is ready
- [ ] Custom domain configurato in GitHub Pages
- [ ] HTTPS enforced (checkbox spuntato)
- [ ] `./tools/check_assetlinks.sh` → ✅ endpoint valid
- [ ] Workflow GitHub Actions mostra success ✅
- [ ] (Opzionale) Ricevuta email/Issue di conferma

Se tutti ✅ → Vai su Play Console e ricontrolla!

---

**Tempo stimato totale:** 30-60 minuti (di cui 20-40 minuti attesa DNS/certificato)

**File utili:**
- [docs/DNS_SETUP.md](docs/DNS_SETUP.md) - Guida DNS dettagliata
- [docs/NOTIFICATIONS_SETUP.md](docs/NOTIFICATIONS_SETUP.md) - Setup email opzionale
- [tools/check_dns.sh](tools/check_dns.sh) - Verifica DNS
- [tools/check_assetlinks.sh](tools/check_assetlinks.sh) - Verifica endpoint
- [tools/setup_github_pages.sh](tools/setup_github_pages.sh) - Helper setup

**Creato:** 29 Dicembre 2025
