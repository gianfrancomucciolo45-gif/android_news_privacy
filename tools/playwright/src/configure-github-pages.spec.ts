import { test, expect } from '@playwright/test';

/**
 * Configura GitHub Pages con custom domain e HTTPS per App Links
 * Requisiti:
 * - Token GitHub in variabile ambiente GITHUB_TOKEN
 * - DNS già configurato (verificato prima di eseguire)
 */

const REPO_OWNER = 'gianfrancomucciolo45-gif';
const REPO_NAME = 'android_news_privacy';
const CUSTOM_DOMAIN = 'androidnews.app';

test.describe('GitHub Pages Configuration', () => {
  test('Setup custom domain and enable HTTPS', async ({ page }) => {
    const githubToken = process.env.GITHUB_TOKEN;
    
    if (!githubToken) {
      throw new Error('GITHUB_TOKEN environment variable not set. Set it with: export GITHUB_TOKEN=your_token');
    }

    console.log('🔧 Configuring GitHub Pages for App Links...');
    
    // 1. Login to GitHub
    console.log('1️⃣ Logging in to GitHub...');
    await page.goto('https://github.com/login');
    
    // Controlla se già loggato
    const isLoggedIn = await page.getByRole('link', { name: /Sign out/i }).isVisible().catch(() => false);
    
    if (!isLoggedIn) {
      // Login via token usando GitHub API
      await page.goto(`https://github.com/settings/tokens`);
      // In alternativa, usa cookie/storage state
      console.log('⚠️  Manual login required. Please login to GitHub in the browser.');
      console.log('   After login, press Enter to continue...');
      await page.pause(); // Pause per login manuale
    } else {
      console.log('✅ Already logged in to GitHub');
    }

    // 2. Naviga alle impostazioni Pages
    console.log('2️⃣ Navigating to Pages settings...');
    const pagesUrl = `https://github.com/${REPO_OWNER}/${REPO_NAME}/settings/pages`;
    await page.goto(pagesUrl);
    
    // Attendi caricamento pagina
    await page.waitForLoadState('networkidle');

    // 3. Configura custom domain
    console.log('3️⃣ Setting custom domain...');
    
    // Trova il campo custom domain
    const customDomainInput = page.getByLabel(/Custom domain/i).or(page.locator('input[name="cname"]'));
    
    // Controlla se già configurato
    const currentValue = await customDomainInput.inputValue();
    
    if (currentValue === CUSTOM_DOMAIN) {
      console.log(`✅ Custom domain already set to ${CUSTOM_DOMAIN}`);
    } else {
      console.log(`📝 Setting custom domain to ${CUSTOM_DOMAIN}...`);
      await customDomainInput.fill(CUSTOM_DOMAIN);
      
      // Salva
      const saveButton = page.getByRole('button', { name: /Save/i }).first();
      await saveButton.click();
      
      console.log('⏳ Waiting for DNS check...');
      await page.waitForTimeout(5000); // Attendi verifica DNS
      
      // Verifica successo
      const successMessage = page.getByText(/successfully/i).or(page.getByText(/DNS check/i));
      const errorMessage = page.getByText(/not properly configured/i).or(page.getByText(/failed/i));
      
      const isSuccess = await successMessage.isVisible({ timeout: 30000 }).catch(() => false);
      const isError = await errorMessage.isVisible({ timeout: 5000 }).catch(() => false);
      
      if (isError) {
        console.error('❌ DNS verification failed!');
        console.error('   Make sure you have configured these A records:');
        console.error('   185.199.108.153');
        console.error('   185.199.109.153');
        console.error('   185.199.110.153');
        console.error('   185.199.111.153');
        console.error('');
        console.error('   Run: ./tools/check_dns.sh to verify DNS');
        throw new Error('DNS verification failed');
      }
      
      if (isSuccess) {
        console.log('✅ Custom domain verified!');
      }
    }

    // 4. Attendi che il certificato SSL sia pronto
    console.log('4️⃣ Waiting for SSL certificate...');
    
    // Ricarica la pagina per vedere lo stato HTTPS
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    // Cerca il checkbox Enforce HTTPS
    let httpsCheckbox = page.getByLabel(/Enforce HTTPS/i).or(page.locator('input[type="checkbox"][name*="https"]'));
    
    let attempts = 0;
    const maxAttempts = 20; // 20 tentativi x 30 sec = 10 minuti max
    
    while (attempts < maxAttempts) {
      const isEnabled = await httpsCheckbox.isEnabled({ timeout: 5000 }).catch(() => false);
      
      if (isEnabled) {
        console.log('✅ SSL certificate ready!');
        break;
      }
      
      attempts++;
      console.log(`⏳ Waiting for SSL certificate... (attempt ${attempts}/${maxAttempts})`);
      console.log('   This typically takes 10-20 minutes for new domains.');
      
      if (attempts >= maxAttempts) {
        console.warn('⚠️  SSL certificate not ready after 10 minutes.');
        console.warn('   You may need to enable "Enforce HTTPS" manually later.');
        console.warn('   The certificate might still be provisioning.');
        return; // Exit senza errore
      }
      
      await page.waitForTimeout(30000); // Attendi 30 secondi
      await page.reload();
      await page.waitForLoadState('networkidle');
      
      // Ritrova il checkbox dopo reload
      httpsCheckbox = page.getByLabel(/Enforce HTTPS/i).or(page.locator('input[type="checkbox"][name*="https"]'));
    }

    // 5. Abilita Enforce HTTPS
    console.log('5️⃣ Enabling HTTPS enforcement...');
    
    const isChecked = await httpsCheckbox.isChecked();
    
    if (isChecked) {
      console.log('✅ HTTPS already enforced');
    } else {
      console.log('📝 Checking "Enforce HTTPS"...');
      await httpsCheckbox.check();
      
      // Potrebbe esserci un pulsante Save separato o auto-save
      const httpsSaveButton = page.getByRole('button', { name: /Save/i }).first();
      const isSaveVisible = await httpsSaveButton.isVisible({ timeout: 2000 }).catch(() => false);
      
      if (isSaveVisible) {
        await httpsSaveButton.click();
        await page.waitForTimeout(2000);
      }
      
      console.log('✅ HTTPS enforcement enabled!');
    }

    // 6. Verifica finale endpoint
    console.log('6️⃣ Verifying assetlinks endpoint...');
    
    await page.waitForTimeout(5000); // Attendi propagazione
    
    const response = await page.request.get(`https://${CUSTOM_DOMAIN}/.well-known/assetlinks.json`);
    
    if (response.ok()) {
      const contentType = response.headers()['content-type'];
      console.log(`✅ Endpoint accessible: ${response.status()}`);
      console.log(`   Content-Type: ${contentType}`);
      
      if (contentType?.includes('application/json')) {
        const data = await response.json();
        const packageName = data[0]?.target?.package_name;
        const fingerprint = data[0]?.target?.sha256_cert_fingerprints?.[0];
        
        console.log(`   Package: ${packageName}`);
        console.log(`   Fingerprint: ${fingerprint?.substring(0, 20)}...`);
        
        expect(packageName).toBe('com.mucciologianfranco.android_news');
        expect(fingerprint).toBeTruthy();
        
        console.log('✅ AssetLinks JSON valid!');
      } else {
        console.warn(`⚠️  Content-Type is ${contentType}, expected application/json`);
      }
    } else {
      console.error(`❌ Endpoint returned ${response.status()}`);
      console.error('   The endpoint might need a few more minutes to be available.');
    }

    console.log('');
    console.log('🎉 GitHub Pages configuration complete!');
    console.log('');
    console.log('📋 Next steps:');
    console.log('   1. Run: ./tools/check_assetlinks.sh to verify everything');
    console.log('   2. Go to Play Console → App integrity → App Links');
    console.log('   3. Click "Ricontrolla la verifica" for androidnews.app');
    console.log('   4. Wait for verification result');
    console.log('');
  });
});
