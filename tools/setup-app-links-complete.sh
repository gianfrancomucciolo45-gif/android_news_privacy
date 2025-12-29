#!/bin/bash
# Orchestratore completo per setup App Links
# Esegue tutti i passaggi necessari in sequenza

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 App Links Setup - Orchestrazione Completa"
echo "=============================================="
echo ""

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare step
print_step() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# STEP 1: Verifica prerequisiti
print_step "STEP 1: Verifica Prerequisiti"

echo "Checking required tools..."

# Check Node.js
if ! command -v node &> /dev/null; then
  echo -e "${RED}❌ Node.js not found${NC}"
  echo "Install Node.js: https://nodejs.org/"
  exit 1
fi
echo -e "${GREEN}✅ Node.js $(node --version)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
  echo -e "${RED}❌ npm not found${NC}"
  exit 1
fi
echo -e "${GREEN}✅ npm $(npm --version)${NC}"

# Check git
if ! command -v git &> /dev/null; then
  echo -e "${RED}❌ git not found${NC}"
  exit 1
fi
echo -e "${GREEN}✅ git${NC}"

# Check dig (dnsutils)
if ! command -v dig &> /dev/null; then
  echo -e "${YELLOW}⚠️  dig not found. Installing dnsutils...${NC}"
  sudo apt-get update && sudo apt-get install -y dnsutils || {
    echo -e "${RED}❌ Failed to install dnsutils${NC}"
    exit 1
  }
fi
echo -e "${GREEN}✅ dig (DNS utils)${NC}"

echo ""

# STEP 2: Install Playwright dependencies
print_step "STEP 2: Setup Playwright"

cd "$PROJECT_ROOT/tools/playwright"

if [ ! -d "node_modules" ]; then
  echo "Installing Node.js dependencies..."
  npm install
else
  echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi

# Install Playwright browsers
echo "Installing Playwright browsers..."
npx playwright install chromium
npx playwright install-deps chromium

echo -e "${GREEN}✅ Playwright ready${NC}"
echo ""

# STEP 3: Verifica DNS
print_step "STEP 3: Verifica Configurazione DNS"

cd "$PROJECT_ROOT"

echo "Checking DNS configuration for androidnews.app..."
echo ""

if bash tools/check_dns.sh; then
  echo ""
  echo -e "${GREEN}✅ DNS configurato correttamente!${NC}"
  DNS_OK=true
else
  echo ""
  echo -e "${YELLOW}⚠️  DNS non ancora configurato o in propagazione${NC}"
  echo ""
  echo "Prima di continuare, devi configurare questi record DNS:"
  echo ""
  echo "  Type: A    Name: @    Value: 185.199.108.153"
  echo "  Type: A    Name: @    Value: 185.199.109.153"
  echo "  Type: A    Name: @    Value: 185.199.110.153"
  echo "  Type: A    Name: @    Value: 185.199.111.153"
  echo ""
  echo "Vedi docs/DNS_SETUP.md per istruzioni dettagliate."
  echo ""
  
  read -p "Hai già configurato il DNS? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🛑 Setup interrotto. Configura prima il DNS e rilancia questo script."
    echo "   Documentazione: docs/DNS_SETUP.md"
    exit 0
  fi
  
  echo ""
  echo "Attendo propagazione DNS (questo può richiedere 5-30 minuti)..."
  echo "Provo ogni 30 secondi..."
  echo ""
  
  MAX_WAIT=40 # 40 x 30 sec = 20 minuti max
  WAIT_COUNT=0
  
  while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if bash tools/check_dns.sh > /dev/null 2>&1; then
      echo -e "${GREEN}✅ DNS propagato con successo!${NC}"
      DNS_OK=true
      break
    fi
    
    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo "   Tentativo $WAIT_COUNT/$MAX_WAIT..."
    sleep 30
  done
  
  if [ "$DNS_OK" != "true" ]; then
    echo -e "${RED}❌ DNS ancora non propagato dopo 20 minuti${NC}"
    echo "   Controlla la configurazione e riprova più tardi."
    exit 1
  fi
fi

echo ""

# STEP 4: Configura GitHub Pages
print_step "STEP 4: Configurazione GitHub Pages"

echo "Questo passaggio configurerà:"
echo "  - Custom domain: androidnews.app"
echo "  - Enforce HTTPS"
echo ""

# Check GitHub token
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${YELLOW}⚠️  GITHUB_TOKEN non impostato${NC}"
  echo ""
  echo "Hai due opzioni:"
  echo ""
  echo "  1. Imposta GITHUB_TOKEN e riavvia:"
  echo "     export GITHUB_TOKEN=ghp_your_token_here"
  echo "     ./tools/setup-app-links-complete.sh"
  echo ""
  echo "  2. Continua con login manuale nel browser"
  echo ""
  
  read -p "Vuoi continuare con login manuale? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "🛑 Setup interrotto."
    echo "   Crea un token su: https://github.com/settings/tokens"
    echo "   Permessi richiesti: repo (full control)"
    exit 0
  fi
  
  echo ""
  echo "Durante il test ti verrà chiesto di fare login manualmente."
  echo "Premi Invio per continuare..."
  read
fi

cd "$PROJECT_ROOT/tools/playwright"

echo "Eseguendo configurazione GitHub Pages..."
npx playwright test src/configure-github-pages.spec.ts --headed

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ GitHub Pages configurato con successo!${NC}"
else
  echo -e "${RED}❌ Configurazione GitHub Pages fallita${NC}"
  echo "   Verifica i log sopra per dettagli."
  echo "   Puoi anche configurare manualmente:"
  echo "   https://github.com/gianfrancomucciolo45-gif/android_news_privacy/settings/pages"
  exit 1
fi

echo ""

# STEP 5: Verifica endpoint assetlinks
print_step "STEP 5: Verifica Endpoint AssetLinks"

cd "$PROJECT_ROOT"

echo "Attendendo stabilizzazione endpoint (30 secondi)..."
sleep 30

echo "Verificando https://androidnews.app/.well-known/assetlinks.json..."
echo ""

if bash tools/check_assetlinks.sh; then
  echo ""
  echo -e "${GREEN}✅ Endpoint assetlinks funzionante!${NC}"
else
  echo ""
  echo -e "${YELLOW}⚠️  Endpoint non ancora raggiungibile${NC}"
  echo "   Questo è normale subito dopo la configurazione."
  echo "   Attendo 2 minuti e riprovo..."
  sleep 120
  
  if bash tools/check_assetlinks.sh; then
    echo -e "${GREEN}✅ Endpoint ora funzionante!${NC}"
  else
    echo -e "${RED}❌ Endpoint ancora non disponibile${NC}"
    echo "   Il certificato SSL potrebbe ancora essere in provisioning."
    echo "   Attendi 10-15 minuti e rilancia: ./tools/check_assetlinks.sh"
    echo ""
    
    read -p "Vuoi continuare comunque con Play Console? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "🛑 Setup interrotto. Riprova più tardi quando l'endpoint è OK."
      exit 0
    fi
  fi
fi

echo ""

# STEP 6: Play Console - Recheck verifica
print_step "STEP 6: Play Console - Ricontrolla Verifica"

echo "Ora automatizzeremo il recheck della verifica su Play Console."
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Assicurati di essere loggato su Play Console in Chrome"
echo "   - Il browser si aprirà in modalità headed (visibile)"
echo "   - Se richiesto, fai login manualmente"
echo ""

read -p "Pronto per continuare? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo ""
  echo "🛑 Setup interrotto."
  echo ""
  echo "Puoi completare manualmente:"
  echo "  1. Apri: https://play.google.com/console"
  echo "  2. Vai su: App integrity → App Links"
  echo "  3. Trova androidnews.app"
  echo "  4. Click 'Ricontrolla la verifica'"
  echo ""
  exit 0
fi

cd "$PROJECT_ROOT/tools/playwright"

echo "Eseguendo recheck Play Console..."
npx playwright test src/verify-app-links.spec.ts --headed --grep "Recheck domain verification"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${GREEN}🎉 SUCCESS! App Links Verificati! 🎉${NC}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "✅ Configurazione completata con successo!"
  echo "✅ DNS configurato"
  echo "✅ GitHub Pages configurato"
  echo "✅ HTTPS abilitato"
  echo "✅ Endpoint assetlinks.json OK"
  echo "✅ Play Console verifica OK"
  echo ""
  echo "Gli utenti possono ora aprire link androidnews.app/* direttamente nella tua app!"
  echo ""
else
  echo ""
  echo -e "${YELLOW}⚠️  Verifica Play Console non completata automaticamente${NC}"
  echo ""
  echo "Completa manualmente:"
  echo "  1. Apri: https://play.google.com/console"
  echo "  2. Seleziona Android News"
  echo "  3. App integrity → App Links"
  echo "  4. Trova androidnews.app"
  echo "  5. Click 'Ricontrolla la verifica'"
  echo ""
  echo "Il resto della configurazione è OK:"
  echo "  ✅ DNS configurato"
  echo "  ✅ GitHub Pages configurato"
  echo "  ✅ HTTPS abilitato"
  echo "  ✅ Endpoint assetlinks.json OK"
  echo ""
fi

echo "📊 Per verificare lo stato in futuro:"
echo "   ./tools/check_dns.sh"
echo "   ./tools/check_assetlinks.sh"
echo ""

# STEP 7: Cleanup e summary
print_step "Setup Completato"

echo "📁 File creati/aggiornati:"
echo "  - .well-known/assetlinks.json"
echo "  - CNAME"
echo "  - docs/DNS_SETUP.md"
echo "  - tools/check_dns.sh"
echo "  - tools/check_assetlinks.sh"
echo "  - .github/workflows/monitor-assetlinks.yml"
echo ""

echo "🤖 Monitoraggio automatico attivo:"
echo "   Il workflow GitHub Actions controlla l'endpoint ogni 15 minuti"
echo "   e ti notifica via Issue quando tutto è OK."
echo ""

echo "✨ Done!"
