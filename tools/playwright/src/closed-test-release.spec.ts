import { test, expect, Page } from '@playwright/test';
import { selectApp } from './utils.js';
import fs from 'fs';

// Questo test automatizza (per quanto possibile) la creazione di una release su traccia di test chiuso.
// Limiti: La UI Play Console cambia spesso; selettori potrebbero rompersi. 2FA richiede login salvato (auth/state.json).
// Prerequisiti:
// 1. Esegui: npm run login (con browser non headless) e completa login + 2FA.
// 2. Assicurati di avere app già creata con package name corretto.
// 3. Fornisci AAB in path noto. (Il caricamento file potrebbe richiedere input manuale se Play Console usa componenti custom.)
// 4. Variabili opzionali in .env (APP_NAME, PACKAGE_NAME, RELEASE_NOTES, TESTERS_EMAILS).

const RELEASE_NAME = process.env.RELEASE_NAME ?? 'Closed Test Build';
const RELEASE_NOTES = process.env.RELEASE_NOTES ?? 'Prima build di test chiuso';
const AAB_PATH = process.env.AAB_PATH ?? '../../build/app/outputs/bundle/release/app-release.aab';
const TESTERS_EMAILS = (process.env.TESTERS_EMAILS ?? '').split(',').map(s => s.trim()).filter(Boolean);
const WAIT_MANUAL = (process.env.WAIT_MANUAL ?? 'false').toLowerCase() === 'true';

function logStep(step: string) {
  console.log(`\n[ClosedTesting] ${step}`);
}

// Helper per trovare un link o bottone per sezione Closed testing.
async function gotoClosedTesting(page: Page) {
  const patterns = [/Closed testing|Test chiuso/i, /Internal testing|Test interno/i];
  // Apri sezione Testing / Release
  const releaseMenu = page.getByRole('link', { name: /Testing|Release|Rilascio|Test/i }).first();
  if (await releaseMenu.isVisible().catch(() => false)) {
    await releaseMenu.click();
    await page.waitForLoadState('networkidle');
  }
  for (const p of patterns) {
    const link = page.getByRole('link', { name: p }).first();
    if (await link.isVisible().catch(() => false)) { await link.click(); break; }
    const btn = page.getByRole('button', { name: p }).first();
    if (await btn.isVisible().catch(() => false)) { await btn.click(); break; }
  }
  await page.waitForLoadState('networkidle');
}

async function startNewRelease(page: Page) {
  logStep('Avvio nuova release');
  // Bottone "Create new release" / "Crea nuova release"
  const createButtons = [
    page.getByRole('button', { name: /Create new release|Nuova release|Crea nuova release/i }),
    page.getByRole('button', { name: /New release|Nuova release/i }),
    page.getByRole('link', { name: /Create new release|Nuova release/i }),
  ];
  for (const b of createButtons) {
    if (await b.isVisible().catch(() => false)) { await b.click(); break; }
  }
  await page.waitForTimeout(2000);
  // Campo nome release (se presente)
  const nameField = page.getByRole('textbox', { name: /Release name|Nome release|Name/i }).first();
  if (await nameField.isVisible().catch(() => false)) {
    await nameField.fill(RELEASE_NAME);
  }
}

async function uploadAAB(page: Page) {
  logStep('Upload AAB');
  if (!fs.existsSync(AAB_PATH)) {
    throw new Error(`File AAB non trovato: ${AAB_PATH}`);
  }
  // Input file (potrebbe essere nascosto). Tentiamo selettore generico.
  const fileInput = page.locator('input[type="file"]');
  if (await fileInput.isVisible().catch(() => false)) {
    await fileInput.setInputFiles(AAB_PATH);
  } else {
    console.warn('Input file non visibile: potrebbe richiedere interazione manuale.');
  }
  await page.waitForTimeout(5000); // attesa processamento
  // Verifica caricamento (stringhe possibili)
  const processing = page.getByText(/processing|elaborazione|uploaded|caricato/i).first();
  if (await processing.isVisible().catch(() => false)) {
    await expect(processing).toBeVisible();
  }
}

async function enterReleaseNotes(page: Page) {
  logStep('Inserimento note release');
  const notesAreas = [
    page.getByRole('textbox', { name: /Release notes|Note di rilascio/i }),
    page.locator('textarea').first(),
  ];
  for (const a of notesAreas) {
    if (await a.isVisible().catch(() => false)) { await a.fill(RELEASE_NOTES); break; }
  }
}

async function addTesters(page: Page) {
  logStep('Aggiunta testers');
  if (!TESTERS_EMAILS.length) return;
  // Sezione testers (gruppi email)
  const testerSection = page.getByText(/Testers|Tester/i).first();
  if (await testerSection.isVisible().catch(() => false)) await testerSection.click();
  for (const email of TESTERS_EMAILS) {
    // Potrebbe esserci un campo per aggiungere email singole
    const input = page.getByRole('textbox').filter({ hasNotText: /Release notes|Note/i }).first();
    if (await input.isVisible().catch(() => false)) {
      await input.fill(email);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(500);
    }
  }
}

async function reviewAndSubmit(page: Page) {
  logStep('Review & submit');
  const reviewButtons = [
    page.getByRole('button', { name: /Review and submit|Rivedi e invia|Review/i }),
    page.getByRole('button', { name: /Save|Salva/i }),
  ];
  for (const b of reviewButtons) {
    if (await b.isVisible().catch(() => false)) { await b.click(); break; }
  }
  await page.waitForTimeout(2000);
  const submitButtons = [
    page.getByRole('button', { name: /Submit|Invia|Publish|Pubblica/i }),
  ];
  for (const s of submitButtons) {
    if (await s.isVisible().catch(() => false)) { await s.click(); break; }
  }
  await page.waitForTimeout(5000);
}

// Test principale
test('Closed testing release creation', async ({ page }) => {
  logStep('Inizio test closed testing');
  await selectApp(page); // Usa utils per aprire app
  await gotoClosedTesting(page);
  await startNewRelease(page);
  if (WAIT_MANUAL) {
    logStep('WAIT_MANUAL attivo: pausa per upload manuale (30s)');
    await page.waitForTimeout(30_000);
  } else {
    await uploadAAB(page);
  }
  await enterReleaseNotes(page);
  await addTesters(page);
  await reviewAndSubmit(page);
  // Verifica presenza di stato di processing / success
  const successIndicator = page.getByText(/Release created|Release submitted|Release pending review|Release inviato|In review|In revisione/i).first();
  await expect(successIndicator).toBeVisible({ timeout: 60_000 });
  logStep('Test chiuso completato con successo');
});
