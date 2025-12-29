# Android News - App Links & Privacy

Questo repository contiene:
- Privacy Policy per l'applicazione Android News
- Digital Asset Links per App Links verification

## 🌐 Link Pubblici

- **Privacy Policy:** https://androidnews.app (o https://gianfrancomucciolo45-gif.github.io/android_news_privacy/)
- **Asset Links:** https://androidnews.app/.well-known/assetlinks.json

## 🔧 Setup App Links (Play Console)

**Stato:** In configurazione ⚙️

Per completare la verifica App Links, segui la [**QUICK_START.md**](QUICK_START.md) in 3 passi:

1. ⚙️ **Configurare DNS** (A records GitHub Pages)
2. 🌐 **Attivare Custom Domain** su GitHub Pages + HTTPS
3. 🎯 **Ricontrollare verifica** su Play Console

### Strumenti di verifica

```bash
# Verifica DNS
./tools/check_dns.sh

# Verifica endpoint assetlinks
./tools/check_assetlinks.sh

# Helper setup GitHub Pages
./tools/setup_github_pages.sh
```

### Documentazione completa

- [QUICK_START.md](QUICK_START.md) - Guida rapida setup
- [docs/DNS_SETUP.md](docs/DNS_SETUP.md) - Configurazione DNS dettagliata
- [docs/NOTIFICATIONS_SETUP.md](docs/NOTIFICATIONS_SETUP.md) - Email notifications (opzionale)

## 📱 Privacy Policy

Per aggiornare la privacy policy:
1. Modifica il file `index.md`
2. Aggiorna la data in "Ultimo aggiornamento"
3. Commit e push delle modifiche
4. Le modifiche saranno automaticamente pubblicate su GitHub Pages

## 🤖 Monitoraggio Automatico

Il workflow GitHub Actions (`.github/workflows/monitor-assetlinks.yml`) controlla l'endpoint ogni 15 minuti e notifica quando diventa disponibile:

- ✅ Verifica DNS
- ✅ Verifica endpoint assetlinks.json
- ✅ Crea Issue su successo
- ✅ Invia email (opzionale, con SMTP secrets)

## 📞 Contatti

Per domande: gianfrancomucciolo45@gmail.com
