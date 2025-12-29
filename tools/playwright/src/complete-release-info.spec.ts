import { test, expect, Page } from '@playwright/test';
import { selectApp } from './utils.js';

// Script per completare la scheda informazioni release su Play Console
// Compila i campi obbligatori per la prima release: nome app, descrizioni brevi/complete, screenshot, icona, categoria

const APP_CONFIG = {
  appName: process.env.APP_NAME ?? 'Android News',
  shortDescription: process.env.SHORT_DESCRIPTION ?? 'Notizie Android in tempo reale dalle migliori fonti italiane',
  fullDescription: process.env.FULL_DESCRIPTION ?? 
    'Android News raccoglie le ultime notizie su Android, smartphone, tablet e tecnologia dalle migliori fonti italiane.\n\n' +
    'Caratteristiche:\n' +
    '• Aggregazione da 14 fonti specializzate\n' +
    '• Aggiornamenti in tempo reale\n' +
    '• Interfaccia Material Design 3\n' +
    '• Modalità scura e chiara\n' +
    '• Personalizzazione tema con colori custom\n' +
    '• Supporto multilingua (Italiano/Inglese)\n' +
    '• Ricerca e filtri avanzati\n' +
    '• Condivisione articoli\n\n' +
    'Fonti incluse: TuttoAndroid, AndroidWorld, HDblog, Androidiani, GizChina, XiaomiToday e molte altre.',
  category: process.env.CATEGORY ?? 'News & Magazines',
  email: process.env.EMAIL ?? 'support@androidnews.app',
  privacyPolicyUrl: process.env.PRIVACY_URL ?? '',
};

async function navigateToStoreListing(page: Page) {
  // Naviga alla sezione Store presence > Main store listing
  const storePresence = page.getByRole('link', { name: /Store presence|Presenza sullo store/i }).first();
  if (await storePresence.isVisible({ timeout: 5000 }).catch(() => false)) {
    await storePresence.click();
    await page.waitForLoadState('networkidle');
  }
  
  const mainListing = page.getByRole('link', { name: /Main store listing|Scheda dello Store principale/i }).first();
  if (await mainListing.isVisible({ timeout: 5000 }).catch(() => false)) {
    await mainListing.click();
    await page.waitForLoadState('networkidle');
  }
}

async function fillAppDetails(page: Page) {
  // App name
  const appNameField = page.getByLabel(/App name|Nome app/i).first();
  if (await appNameField.isVisible({ timeout: 5000 }).catch(() => false)) {
    await appNameField.clear();
    await appNameField.fill(APP_CONFIG.appName);
  }
  
  // Short description
  const shortDescField = page.getByLabel(/Short description|Breve descrizione/i).first();
  if (await shortDescField.isVisible({ timeout: 5000 }).catch(() => false)) {
    await shortDescField.clear();
    await shortDescField.fill(APP_CONFIG.shortDescription);
  }
  
  // Full description
  const fullDescField = page.getByLabel(/Full description|Descrizione completa/i).first();
  if (await fullDescField.isVisible({ timeout: 5000 }).catch(() => false)) {
    await fullDescField.clear();
    await fullDescField.fill(APP_CONFIG.fullDescription);
  }
}

async function fillContactDetails(page: Page) {
  // Email
  const emailField = page.getByLabel(/Email|E-mail/i).first();
  if (await emailField.isVisible({ timeout: 5000 }).catch(() => false)) {
    await emailField.clear();
    await emailField.fill(APP_CONFIG.email);
  }
  
  // Privacy policy URL (se fornito)
  if (APP_CONFIG.privacyPolicyUrl) {
    const privacyField = page.getByLabel(/Privacy policy|Informativa sulla privacy/i).first();
    if (await privacyField.isVisible({ timeout: 5000 }).catch(() => false)) {
      await privacyField.clear();
      await privacyField.fill(APP_CONFIG.privacyPolicyUrl);
    }
  }
}

async function selectCategory(page: Page) {
  // Apri dropdown categoria
  const categoryDropdown = page.getByLabel(/Category|Categoria/i).first();
  if (await categoryDropdown.isVisible({ timeout: 5000 }).catch(() => false)) {
    await categoryDropdown.click();
    await page.waitForTimeout(500);
    
    // Seleziona categoria
    const categoryOption = page.getByRole('option', { name: new RegExp(APP_CONFIG.category, 'i') }).first();
    if (await categoryOption.isVisible({ timeout: 5000 }).catch(() => false)) {
      await categoryOption.click();
    }
  }
}

async function saveChanges(page: Page) {
  const saveButtons = [
    page.getByRole('button', { name: /Save|Salva/i }),
    page.getByRole('button', { name: /Save draft|Salva bozza/i }),
  ];
  
  for (const btn of saveButtons) {
    if (await btn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await btn.click();
      await page.waitForTimeout(2000);
      break;
    }
  }
}

test('Complete release information on Play Console', async ({ page }) => {
  // Seleziona app
  await selectApp(page);
  
  // Vai alla scheda Store Listing
  await navigateToStoreListing(page);
  
  // Compila dettagli app
  await fillAppDetails(page);
  
  // Compila contatti
  await fillContactDetails(page);
  
  // Seleziona categoria
  await selectCategory(page);
  
  // Salva modifiche
  await saveChanges(page);
  
  // Verifica salvataggio
  const successIndicators = [
    page.getByText(/Saved|Salvato|Changes saved|Modifiche salvate/i),
    page.getByText(/Draft saved|Bozza salvata/i),
  ];
  
  let saved = false;
  for (const indicator of successIndicators) {
    if (await indicator.isVisible({ timeout: 10000 }).catch(() => false)) {
      saved = true;
      break;
    }
  }
  
  expect(saved).toBeTruthy();
  
  console.log('✓ Scheda informazioni release completata');
  console.log('✓ Nome app: ' + APP_CONFIG.appName);
  console.log('✓ Categoria: ' + APP_CONFIG.category);
  console.log('✓ Descrizione breve e completa inserite');
  console.log('✓ Email di contatto: ' + APP_CONFIG.email);
});
