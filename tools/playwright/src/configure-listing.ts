import { chromium } from 'playwright';
import { clickSave, env, gotoMainStoreListing, selectApp } from './utils.js';

async function fillTextIfVisible(selector: string, value: string, page: any) {
  const el = page.locator(selector).first();
  if (await el.isVisible().catch(() => false)) {
    await el.fill(value);
  }
}

async function main() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({ storageState: 'auth/state.json' });
  const page = await context.newPage();

  // Seleziona app
  await selectApp(page);
  // Vai alla scheda store principale
  await gotoMainStoreListing(page);

  // Imposta lingua di default se campo presente
  const localeCombo = page.getByRole('combobox', { name: /Default language|Lingua predefinita/i });
  if (await localeCombo.isVisible().catch(() => false)) {
    await localeCombo.click();
    await page.getByRole('option', { name: new RegExp(env.DEFAULT_LOCALE, 'i') }).first().click().catch(() => {});
  }

  // Titolo app (in genere già impostato da creazione, ma tentiamo)
  await fillTextIfVisible('textarea[aria-label*="App name" i], textarea[aria-label*="Nome app" i]', env.APP_NAME, page);

  // Short description
  await fillTextIfVisible('textarea[aria-label*="Short description" i], textarea[aria-label*="Breve descrizione" i]', env.SHORT_DESCRIPTION, page);

  // Full description
  await fillTextIfVisible('textarea[aria-label*="Full description" i], textarea[aria-label*="Descrizione completa" i]', env.FULL_DESCRIPTION, page);

  // Categoria (potrebbe essere in un’altra pagina: tentiamo via combobox)
  const categoryCombo = page.getByRole('combobox', { name: /Category|Categoria/i });
  if (await categoryCombo.isVisible().catch(() => false)) {
    await categoryCombo.click();
    await page.getByRole('option', { name: new RegExp(env.CATEGORY, 'i') }).first().click().catch(() => {});
  }

  // Contatti (email, website)
  await fillTextIfVisible('input[aria-label*="Email" i], input[aria-label*="E-mail" i]', env.EMAIL_CONTACT, page);
  await fillTextIfVisible('input[aria-label*="Website" i], input[aria-label*="Sito web" i]', env.WEBSITE, page);
  await fillTextIfVisible('input[aria-label*="Privacy policy" i], input[aria-label*="Informativa sulla privacy" i]', env.PRIVACY_URL, page);

  // Salva
  await clickSave(page);
  await page.waitForTimeout(2000);

  console.log('Scheda store principale aggiornata.');
  await browser.close();
}

main().catch((e) => { console.error(e); process.exit(1); });
