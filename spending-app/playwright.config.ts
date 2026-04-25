import { defineConfig, devices } from '@playwright/test';

const appUrl = process.env.APP_BASE_URL ?? 'http://127.0.0.1:60605';
const backendUrl = process.env.BACKEND_BASE_URL ?? 'http://127.0.0.1:8000';

const backendCommand =
  process.platform === 'win32'
    ? '.venv\\Scripts\\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000'
    : '.venv/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000';

export default defineConfig({
  testDir: './e2e',
  timeout: 90_000,
  expect: {
    timeout: 20_000
  },
  fullyParallel: false,
  workers: 1,
  reporter: [['list'], ['html']],
  use: {
    baseURL: appUrl,
    viewport: {
      width: 1280,
      height: 900
    },
    deviceScaleFactor: 1,
    trace: 'on',
    screenshot: 'on',
    video: {
      mode: 'on',
      size: {
        width: 1280,
        height: 900
      }
    },
    launchOptions: {
      args: ['--window-size=1280,900']
    }
  },
  webServer: [
    {
      command: backendCommand,
      cwd: './backend',
      url: `${backendUrl}/health`,
      reuseExistingServer: true,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe'
    },
    {
      command: 'npx http-server mobile/build/web -a 127.0.0.1 -p 60605 -c-1',
      cwd: '.',
      url: appUrl,
      reuseExistingServer: false,
      timeout: 60_000,
      stdout: 'pipe',
      stderr: 'pipe'
    }
  ],
  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome']
      }
    }
  ]
});