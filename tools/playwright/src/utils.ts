import * as dotenv from 'dotenv';
import { Page } from 'playwright';

dotenv.config({ path: new URL('../.env', import.meta.url).pathname });

export const env = {
  APP_NAME: process.env.APP_NAME ?? 'Android News',
  DEFAULT_LOCALE: process.env.DEFAULT_LOCALE ?? 'it-IT',
  SHORT_DESCRIPTION: process.env.SHORT_DESCRIPTION ?? '',
  FULL_DESCRIPTION: process.env.FULL_DESCRIPTION ?? '',
  CATEGORY: process.env.CATEGORY ?? 'News & Magazines',
  EMAIL_CONTACT: process.env.EMAIL_CONTACT ?? '',
  WEBSITE: process.env.WEBSITE ?? '',
  PRIVACY_URL: process.env.PRIVACY_URL ?? '',
  COUNTRIES: (process.env.COUNTRIES ?? 'IT').split(',').map(s => s.trim()).filter(Boolean),
  PRICING_FREE: (process.env.PRICING_FREE ?? 'true').toLowerCase() === 'true',
  SELECT_BY: process.env.SELECT_BY ?? 'title',
  PACKAGE_NAME: process.env.PACKAGE_NAME ?? '',
};

export async function openPlayConsole(page: Page) {
  await page.goto('https://play.google.com/console/u/0/developers');
  await page.waitForLoadState('domcontentloaded');
}

export async function selectApp(page: Page) {
  // Vai alla lista app
  await openPlayConsole(page);
  // Prova a cliccare "Tutte le app" o simile
  const allAppsLocators = [
    page.getByRole('link', { name: /All apps|Tutte le app|Tutte le applicazioni/i }),
    page.getByRole('button', { name: /All apps|Tutte le app|Tutte le applicazioni/i }),
  ];
  for (const l of allAppsLocators) {
    if (await l.isVisible().catch(() => false)) { await l.click(); break; }
  }
  await page.waitForLoadState('networkidle');

  if (env.SELECT_BY === 'package' && env.PACKAGE_NAME) {
    // Usa la search per trovare per package
    const search = page.getByPlaceholder(/Search apps|Cerca app/i);
    if (await search.isVisible().catch(() => false)) {
      await search.fill(env.PACKAGE_NAME);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(1000);
    }
  }

  // Clicca riga con titolo app
  const appRow = page.locator(`text=${env.APP_NAME}`).first();
  await appRow.waitFor({ timeout: 10_000 });
  await appRow.click();
  await page.waitForLoadState('networkidle');
}

export async function gotoMainStoreListing(page: Page) {
  // Tentativi multipli per navigare alla scheda store
  const candidates = [
    /Main store listing|Scheda dello Store principale|Scheda store principale/i,
    /Store presence|Presenza sullo store/i,
  ];
  // Apri menu di navigazione se esiste
  const navBtn = page.getByRole('button', { name: /menu|navigation/i });
  if (await navBtn.isVisible().catch(() => false)) await navBtn.click();
  // Prova a cliccare voci
  for (const r of candidates) {
    const link = page.getByRole('link', { name: r }).first();
    if (await link.isVisible().catch(() => false)) { await link.click(); break; }
    const btn = page.getByRole('button', { name: r }).first();
    if (await btn.isVisible().catch(() => false)) { await btn.click(); break; }
  }
  // Se ha una struttura a due livelli
  const mainListing = page.getByRole('link', { name: /Main store listing|Scheda dello Store principale/i }).first();
  if (await mainListing.isVisible().catch(() => false)) {
    await mainListing.click();
  }
  await page.waitForLoadState('networkidle');
}

export async function clickSave(page: Page) {
  const saveButtons = [
    page.getByRole('button', { name: /Save|Salva/i }),
    page.getByRole('button', { name: /Submit|Invia/i }),
  ];
  for (const b of saveButtons) {
    if (await b.isVisible().catch(() => false)) { await b.click(); return; }
  }
}
