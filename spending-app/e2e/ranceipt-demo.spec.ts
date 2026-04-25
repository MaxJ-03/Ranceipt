import { expect, test } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const backendUrl = process.env.BACKEND_BASE_URL ?? 'http://127.0.0.1:8000';
const flutterSessionStorageKey = 'flutter.backend_session_token';

function getReceiptFixturePath(): string {
  const candidates = [
    path.resolve(__dirname, 'fixtures', 'demo-receipt.jpg'),
    path.resolve(__dirname, 'fixtures', 'demo-receipt.jpg.jpeg'),
    path.resolve(__dirname, 'fixtures', 'demo-receipt.jpeg'),
    path.resolve(__dirname, 'fixtures', 'demo-receipt.png')
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }

  throw new Error('Missing receipt fixture image in e2e/fixtures.');
}

async function seedAndLoginDemoUser(request: any): Promise<string> {
  const health = await request.get(`${backendUrl}/health`);
  expect(health.ok(), await health.text()).toBeTruthy();

  const seed = await request.post(`${backendUrl}/demo/seed`);
  expect(seed.ok(), await seed.text()).toBeTruthy();

  const login = await request.post(`${backendUrl}/auth/bunq/sandbox-login`);
  expect(login.ok(), await login.text()).toBeTruthy();

  const loginJson = await login.json();
  const token = loginJson.session_token;

  expect(token).toBeTruthy();

  return token as string;
}

async function openFlutterApp(page: any): Promise<void> {
  page.on('pageerror', (error: Error) => {
    console.log('BROWSER PAGE ERROR:', error.message);
    console.log(error.stack);
  });

  page.on('console', (msg: any) => {
    console.log(`BROWSER ${msg.type().toUpperCase()}:`, msg.text());
  });

  await page.goto('/', {
    waitUntil: 'domcontentloaded',
    timeout: 60_000
  });

  await page.waitForSelector('flt-glass-pane', {
    state: 'attached',
    timeout: 60_000
  });

  await page.waitForTimeout(6000);
}

async function goToReceiptsTab(page: any): Promise<void> {
  await page.mouse.click(1065, 860);
  await page.waitForTimeout(2000);
}

async function goToStatsTab(page: any): Promise<void> {
  await page.mouse.click(640, 860);
  await page.waitForTimeout(2000);
}

test.beforeEach(async ({ page, request }) => {
  const token = await seedAndLoginDemoUser(request);

  await page.addInitScript(
    ({ key, value }) => {
      window.localStorage.setItem(key, JSON.stringify(value));
    },
    {
      key: flutterSessionStorageKey,
      value: token
    }
  );
});

test('dashboard opens with demo data', async ({ page }) => {
  await openFlutterApp(page);

  await page.screenshot({
    path: 'test-results/01-dashboard-open.png',
    fullPage: true
  });

  const health = await page.request.get(`${backendUrl}/health`);
  expect(health.ok()).toBeTruthy();

  const status = await page.request.get(`${backendUrl}/demo/status`);
  expect(status.ok(), await status.text()).toBeTruthy();
});

test('receipts tab opens with demo receipts', async ({ page }) => {
  await openFlutterApp(page);
  await goToReceiptsTab(page);

  await page.screenshot({
    path: 'test-results/02-receipts-tab.png',
    fullPage: true
  });
});

test('stats tab opens', async ({ page }) => {
  await openFlutterApp(page);
  await goToStatsTab(page);

  await page.screenshot({
    path: 'test-results/03-stats-tab.png',
    fullPage: true
  });
});

test('upload receipt from receipts tab and record loading', async ({ page }) => {
  await openFlutterApp(page);
  await goToReceiptsTab(page);

  const receiptImagePath = getReceiptFixturePath();

  await page.screenshot({
    path: 'test-results/04-before-upload.png',
    fullPage: true
  });

  // Click floating Add button on Receipts page.
  await page.mouse.click(1185, 780);
  await page.waitForTimeout(1000);

  await page.screenshot({
    path: 'test-results/05-add-receipt-sheet.png',
    fullPage: true
  });

  // Click "Upload photo" in the bottom sheet.
  const fileChooserPromise = page.waitForEvent('filechooser').catch(() => null);

  await page.mouse.click(640, 735);

  const fileChooser = await fileChooserPromise;

  if (fileChooser) {
    await fileChooser.setFiles(receiptImagePath);
  } else {
    const fileInput = page.locator('input[type="file"]').first();

    await expect(fileInput).toBeAttached({
      timeout: 20_000
    });

    await fileInput.setInputFiles(receiptImagePath);
  }

  // Let loading overlay and upload/fallback finish.
  await page.waitForTimeout(5000);

  await page.screenshot({
    path: 'test-results/06-after-upload.png',
    fullPage: true
  });

  // Stay open briefly so video clearly records the result.
  await page.waitForTimeout(3000);
});