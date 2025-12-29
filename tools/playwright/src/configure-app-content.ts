import { chromium } from 'playwright';
import { env, selectApp } from './utils.js';

async function navigateToAppContent(page: any) {
  // App content / Contenuti dell'app
  const contentLink = page.getByRole('link', { name: /App content|Contenuti dell'app/i }).first();
  if (await contentLink.isVisible().catch(() => false)) {
    await contentLink.click();
  } else {
    // Talvolta sotto Policy > App content
    const policy = page.getByRole('link', { name: /Policy/i }).first();
    if (await policy.isVisible().catch(() => false)) {
      await policy.click();
      await page.getByRole('link', { name: /App content|Contenuti dell'app/i }).first().click().catch(() => {});
    }
  }
  await page.waitForLoadState('networkidle');
}

async function answerSections(page: any) {
  // Alcune sezioni richiedono input manuali e variano molto.
  // Precompiliamo i più comuni step togglando "Accesso all'app", "Pubblicità" e "Target audience" se possibile.

  // App access: dichiarazione accesso completo
  const appAccess = page.getByRole('link', { name: /App access|Accesso all'app/i }).first();
  if (await appAccess.isVisible().catch(() => false)) {
    await appAccess.click();
    const allAccess = page.getByLabel(/All functionality is available|Tutte le funzionalità sono disponibili/i);
    if (await allAccess.isVisible().catch(() => false)) await allAccess.check().catch(() => {});
    const save = page.getByRole('button', { name: /Save|Salva/i }).first();
    if (await save.isVisible().catch(() => false)) await save.click();
    await page.goBack().catch(() => {});
  }

  // Ads
  const ads = page.getByRole('link', { name: /Ads|Pubblicità/i }).first();
  if (await ads.isVisible().catch(() => false)) {
    await ads.click();
    // Se non mostriamo pubblicità
    const noAds = page.getByLabel(/Does not contain ads|Non contiene annunci/i);
    if (await noAds.isVisible().catch(() => false)) await noAds.check().catch(() => {});
    const save = page.getByRole('button', { name: /Save|Salva/i }).first();
    if (await save.isVisible().catch(() => false)) await save.click();
    await page.goBack().catch(() => {});
  }

  // Target audience
  const audience = page.getByRole('link', { name: /Target audience|Pubblico di destinazione/i }).first();
  if (await audience.isVisible().catch(() => false)) {
    await audience.click();
    // 13+ (non target bambini) come default conservativo
    const thirteenPlus = page.getByLabel(/13"+|13\+|13 years or older|13 anni o più/i);
    if (await thirteenPlus.isVisible().catch(() => false)) await thirteenPlus.check().catch(() => {});
    const save = page.getByRole('button', { name: /Save|Salva/i }).first();
    if (await save.isVisible().catch(() => false)) await save.click();
    await page.goBack().catch(() => {});
  }

  // Content rating & Data safety richiedono questionari dettagliati: lascio i passaggi da completare manualmente
  console.log('Nota: completa manualmente "Content rating" e "Data safety" (questionari variabili).');
}

async function main() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ storageState: 'auth/state.json' });
  const page = await context.newPage();
  await selectApp(page);
  await navigateToAppContent(page);
  await answerSections(page);
  console.log('Sezioni base di App Content precompilate.');
  await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
