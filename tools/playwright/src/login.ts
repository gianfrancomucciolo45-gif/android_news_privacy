import { chromium } from 'playwright';
import * as fs from 'node:fs/promises';
import * as path from 'node:path';
import { openPlayConsole } from './utils.js';

async function main() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();
  console.log('Aprendo Play Console: effettua il login manualmente (2FA inclusa).');
  await openPlayConsole(page);
  console.log('Attendo che la pagina sia autenticata e caricata...');
  // Attendi che si veda un elemento tipico dell'area autenticata
  await page.waitForSelector('text=/All apps|Tutte le app|Tutte le applicazioni/', { timeout: 120_000 }).catch(() => {});

  // Salva lo storage state
  const authDir = path.resolve('auth');
  await fs.mkdir(authDir, { recursive: true });
  await context.storageState({ path: path.join(authDir, 'state.json') });
  console.log('Sessione salvata in auth/state.json');
  await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
