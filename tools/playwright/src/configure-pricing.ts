import { chromium } from 'playwright';
import { env, selectApp } from './utils.js';

async function goToPricing(page: any) {
  // Naviga a Pricing & distribution / Prezzi e distribuzione
  const paths = [
    /Pricing & distribution|Prezzi e distribuzione/i,
    /Setup|Configurazione/i,
  ];
  for (const r of paths) {
    const link = page.getByRole('link', { name: r }).first();
    if (await link.isVisible().catch(() => false)) { await link.click(); }
  }
  // Sezione prezzi (gratuita)
  const freeRadio = page.getByLabel(/Free|Gratuita/i).or(page.getByRole('radio', { name: /Free|Gratuita/i }));
  if (env.PRICING_FREE && await freeRadio.isVisible().catch(() => false)) {
    await freeRadio.check().catch(() => {});
  }
  // Seleziona paesi
  const manageCountries = page.getByRole('button', { name: /Manage countries|Gestisci paesi|Aggiungi paesi/i }).first();
  if (await manageCountries.isVisible().catch(() => false)) {
    await manageCountries.click();
    for (const c of env.COUNTRIES) {
      await page.getByRole('checkbox', { name: new RegExp(c, 'i') }).check().catch(() => {});
    }
    const apply = page.getByRole('button', { name: /Apply|Applica|Fatto|Done/i }).first();
    if (await apply.isVisible().catch(() => false)) await apply.click();
  }
  // Salva (se presente)
  const save = page.getByRole('button', { name: /Save|Salva/i }).first();
  if (await save.isVisible().catch(() => false)) await save.click();
}

async function main() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ storageState: 'auth/state.json' });
  const page = await context.newPage();
  await selectApp(page);
  await goToPricing(page);
  console.log('Prezzi e distribuzione aggiornati.');
  await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
