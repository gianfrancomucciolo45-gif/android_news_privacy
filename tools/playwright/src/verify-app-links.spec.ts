import { test, expect } from '@playwright/test';

/**
 * Automatizza il recheck della verifica App Links su Play Console
 * Requisiti:
 * - Endpoint assetlinks.json già funzionante
 * - Login Play Console già effettuato (auth/state.json)
 */

const APP_PACKAGE = 'com.mucciologianfranco.android_news';
const DOMAIN = 'androidnews.app';

test.describe('Play Console App Links Verification', () => {
  test('Recheck domain verification', async ({ page }) => {
    console.log('🎯 Starting Play Console App Links recheck...');

    // 1. Naviga a Play Console
    console.log('1️⃣ Navigating to Play Console...');
    await page.goto('https://play.google.com/console');
    await page.waitForLoadState('networkidle');

    // Controlla se serve login
    const needsLogin = await page.getByRole('button', { name: /Sign in/i }).isVisible({ timeout: 5000 }).catch(() => false);
    
    if (needsLogin) {
      console.log('⚠️  Not logged in to Play Console.');
      console.log('   Please login manually and save auth state.');
      console.log('   After login, press Enter to continue...');
      await page.pause();
    }

    // 2. Seleziona l'app
    console.log('2️⃣ Selecting app...');
    
    // Cerca l'app Android News
    const appSelector = page.getByText('Android News').or(page.getByText(APP_PACKAGE));
    const isAppVisible = await appSelector.isVisible({ timeout: 10000 }).catch(() => false);
    
    if (isAppVisible) {
      await appSelector.click();
      console.log('✅ App selected');
    } else {
      console.log('⚠️  Could not find app in list. Navigating directly...');
    }

    // 3. Naviga a App integrity → App Links
    console.log('3️⃣ Navigating to App Links settings...');
    
    // Sidebar navigation
    const appIntegrityLink = page.getByRole('link', { name: /App integrity/i })
      .or(page.getByRole('link', { name: /Integrità app/i }))
      .or(page.getByText(/App integrity/i));
    
    await appIntegrityLink.click({ timeout: 10000 }).catch(async () => {
      console.log('   Trying alternative navigation...');
      // Alternative: cerca nel menu laterale
      await page.getByText(/Setup/i).click();
      await page.getByText(/App integrity/i).click();
    });

    await page.waitForLoadState('networkidle');

    // Cerca tab/link App Links
    const appLinksTab = page.getByRole('tab', { name: /App links/i })
      .or(page.getByRole('link', { name: /App links/i }))
      .or(page.getByText(/Collegamenti app/i));
    
    await appLinksTab.click({ timeout: 10000 });
    await page.waitForLoadState('networkidle');

    console.log('✅ On App Links page');

    // 4. Trova il dominio androidnews.app
    console.log('4️⃣ Finding domain in list...');
    
    const domainRow = page.getByText(DOMAIN);
    const isDomainVisible = await domainRow.isVisible({ timeout: 10000 }).catch(() => false);
    
    if (!isDomainVisible) {
      console.error(`❌ Domain ${DOMAIN} not found in App Links list!`);
      console.error('   Make sure the domain is declared in AndroidManifest.xml');
      throw new Error('Domain not found');
    }

    console.log(`✅ Found domain: ${DOMAIN}`);

    // 5. Click su "Ricontrolla la verifica" / "Recheck verification"
    console.log('5️⃣ Clicking recheck verification...');
    
    // Trova il pulsante recheck nella stessa riga del dominio
    const domainContainer = page.locator(`text=${DOMAIN}`).locator('xpath=ancestor::tr');
    
    const recheckButton = domainContainer.getByRole('button', { name: /Ricontrolla/i })
      .or(domainContainer.getByRole('button', { name: /Recheck/i }))
      .or(domainContainer.getByRole('button', { name: /Verify/i }));
    
    const isRecheckVisible = await recheckButton.isVisible({ timeout: 5000 }).catch(() => false);
    
    if (!isRecheckVisible) {
      console.log('⚠️  Recheck button not visible. Domain might already be verified or verification in progress.');
      
      // Controlla lo stato
      const statusBadge = domainContainer.locator('[data-test-id="status"]').or(domainContainer.getByText(/Verified|Not verified|Pending/i));
      const statusText = await statusBadge.textContent({ timeout: 5000 }).catch(() => 'Unknown');
      
      console.log(`   Current status: ${statusText}`);
      
      if (statusText.includes('Verified') || statusText.includes('Verificat')) {
        console.log('✅ Domain already verified!');
        return;
      }
    } else {
      await recheckButton.click();
      console.log('✅ Recheck triggered');
      
      // 6. Attendi risultato verifica
      console.log('6️⃣ Waiting for verification result...');
      
      await page.waitForTimeout(5000); // Attendi inizio verifica
      
      // Cerca messaggio di successo o errore
      const successIndicator = page.getByText(/successfully verified/i)
        .or(page.getByText(/verificato con successo/i))
        .or(domainContainer.locator('[data-status="verified"]'));
      
      const errorIndicator = page.getByText(/verification failed/i)
        .or(page.getByText(/verifica non riuscita/i))
        .or(page.getByText(/could not verify/i));
      
      let attempts = 0;
      const maxAttempts = 12; // 12 x 5 sec = 1 minuto
      
      while (attempts < maxAttempts) {
        const isSuccess = await successIndicator.isVisible({ timeout: 2000 }).catch(() => false);
        const isError = await errorIndicator.isVisible({ timeout: 2000 }).catch(() => false);
        
        if (isSuccess) {
          console.log('✅✅✅ VERIFICATION SUCCESSFUL! ✅✅✅');
          console.log('');
          console.log('🎉 App Links for androidnews.app are now verified!');
          console.log('   Users can now open links directly in your app.');
          return;
        }
        
        if (isError) {
          console.error('❌ Verification failed!');
          
          // Cerca dettagli errore
          const errorDetails = await page.locator('.error-message').textContent().catch(() => '');
          if (errorDetails) {
            console.error(`   Error: ${errorDetails}`);
          }
          
          console.error('');
          console.error('🔍 Troubleshooting:');
          console.error('   1. Verify endpoint: ./tools/check_assetlinks.sh');
          console.error('   2. Check DNS: ./tools/check_dns.sh');
          console.error('   3. Ensure HTTPS is enforced on GitHub Pages');
          console.error('   4. Wait 10-15 minutes and try again (cache)');
          
          throw new Error('Verification failed');
        }
        
        attempts++;
        console.log(`   Checking... (${attempts}/${maxAttempts})`);
        await page.waitForTimeout(5000);
        await page.reload();
        await page.waitForLoadState('networkidle');
      }
      
      console.log('⏳ Verification still in progress after 1 minute.');
      console.log('   Check back in Play Console later for the result.');
    }

    // Screenshot finale
    await page.screenshot({ path: 'playwright-results/app-links-final.png', fullPage: true });
    console.log('📸 Screenshot saved to playwright-results/app-links-final.png');
  });

  test('Verify domain status', async ({ page }) => {
    console.log('📊 Checking current App Links status...');

    await page.goto('https://play.google.com/console');
    await page.waitForLoadState('networkidle');

    // Navigate to App Links (same as above, simplified)
    try {
      await page.getByText('Android News').click({ timeout: 10000 });
      await page.getByText(/App integrity/i).click({ timeout: 10000 });
      await page.getByText(/App links/i).click({ timeout: 10000 });
      await page.waitForLoadState('networkidle');

      // Find domain status
      const domainRow = page.locator(`text=${DOMAIN}`).locator('xpath=ancestor::tr');
      const statusElement = domainRow.locator('[data-test-id="status"]').or(domainRow.getByText(/Verified|Not verified|Pending/i));
      const status = await statusElement.textContent({ timeout: 5000 }).catch(() => 'Unknown');

      console.log('');
      console.log(`Domain: ${DOMAIN}`);
      console.log(`Status: ${status}`);
      console.log('');

      if (status.includes('Verified') || status.includes('Verificat')) {
        console.log('✅ Domain is verified!');
      } else if (status.includes('Pending') || status.includes('In corso')) {
        console.log('⏳ Verification in progress...');
      } else {
        console.log('❌ Domain not verified');
        console.log('   Run the recheck test to trigger verification.');
      }
    } catch (error) {
      console.error('Failed to check status:', error.message);
    }
  });
});
