# Ranceipt

**Smart Receipt Management & Spending Goals**

Ranceipt is a smart receipt and spending management app that helps users understand their spending habits, track receipts, sync Bunq sandbox transactions, and manage personal saving goals.

This project is currently configured as a **Bunq sandbox demo app**.

---

## Table of Contents

- [The Idea](#the-idea)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Database Setup](#database-setup)
- [Backend Setup](#backend-setup)
- [Demo Data](#demo-data)
- [Bunq Sandbox Login](#bunq-sandbox-login)
- [Flutter Setup](#flutter-setup)
- [Recommended Local Run Order](#recommended-local-run-order)
- [Demo Flow](#demo-flow)

---

## The Idea

Ranceipt transforms the way users manage spending. Instead of manually categorizing receipts or losing track of where money goes, the app processes receipts, organizes purchases into categories, and helps users stay on track with personal financial goals.

---

## Key Features

- **Smart Receipt Recognition** — Capture receipts and process receipt data.
- **Automatic Categorization** — Organize receipt items into spending categories.
- **Personal Spending Goals** — Set and track saving and spending targets.
- **Transaction Overview** — View transactions and spending insights.
- **Bunq Sandbox Integration** — Sync transactions using Bunq sandbox users.
- **Custom Categories** — Use detailed product-level categories for receipt items.
- **Demo Data Seeding** — Populate the database with sample users, transactions, receipts, and goals.

---

## Tech Stack

### Backend

- Python
- FastAPI
- PostgreSQL
- Docker Compose
- Bunq Sandbox API

### Frontend

- Flutter
- Dart

---

## Prerequisites

Install the following before running the project:

- Docker Desktop
- Python 3.12+
- Flutter
- Git

Make sure Docker Desktop is running before starting the database.

---

## Project Structure

```text
spending-app/
  backend/
    app/
    docker-compose.yml
    ranceipt_db_init.sql
    requirements.txt
    .env

  mobile/
    lib/
    pubspec.yaml
```

---

## Environment Setup

Create a `.env` file inside the `backend/` folder:

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=spending_app
DB_ECHO=false

BUNQ_API_BASE_URL=https://public-api.sandbox.bunq.com/v1
BUNQ_SANDBOX_API_KEY=your_bunq_sandbox_api_key_here

APP_SECRET_KEY=change-this-secret
TOKEN_ENCRYPTION_KEY=your_token_encryption_key_here
```

Generate a token encryption key:

```powershell
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Copy the generated value into:

```env
TOKEN_ENCRYPTION_KEY=
```

---

## Database Setup

From the `backend` folder, start Postgres:

```powershell
cd backend
docker compose up -d
```

This starts a PostgreSQL container and initializes the database using:

```text
ranceipt_db_init.sql
```

Check that the container is running:

```powershell
docker ps
```

You should see a container named:

```text
spending_postgres
```

### Resetting the Database

If the database was already created before, the init SQL file will not run again automatically.

To reset the database:

```powershell
docker compose down -v
docker compose up -d
```

**Warning:** this deletes all local database data.

---

## Backend Setup

From the `backend` folder:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Run the backend:

```powershell
python -m uvicorn app.main:app --reload --reload-dir app
```

The backend runs at:

```text
http://127.0.0.1:8000
```

API documentation:

```text
http://127.0.0.1:8000/docs
```

Health check:

```text
http://127.0.0.1:8000/health
```

Expected response:

```json
{
  "status": "ok"
}
```

---

## Demo Data

The project includes a demo seeding flow for local testing.

In Swagger, run:

```text
POST /demo/seed
```

Then check the seeded data:

```text
GET /demo/status
```

This populates the database with sample:

- users
- Bunq sandbox connection records
- transactions
- receipts
- receipt items
- saving goals

---

## Bunq Sandbox Login

This project is configured for **Bunq sandbox-only authentication**.

The app does **not** use real Bunq OAuth in the demo setup.

The active login flow is:

```text
POST /auth/bunq/sandbox-login
```

The backend uses:

```env
BUNQ_SANDBOX_API_KEY=
```

to authenticate against the Bunq sandbox environment and create an internal app session.

The frontend then uses the returned session token for protected API requests.

---

## Flutter Setup

Open a new terminal and go to the mobile folder:

```powershell
cd mobile
flutter pub get
```

Run the app in Chrome:

```powershell
flutter run -d chrome
```

For Flutter web, the backend base URL should be:

```text
http://127.0.0.1:8000
```

For Android emulator, use:

```text
http://10.0.2.2:8000
```

---

## Recommended Local Run Order

### Terminal 1: Database

```powershell
cd backend
docker compose up -d
```

### Terminal 2: Backend

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --reload-dir app
```

### Terminal 3: Flutter

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

---

## Demo Flow

1. Start Docker/Postgres.
2. Start the FastAPI backend.
3. Start the Flutter app.
4. Click **Continue with bunq**.
5. The app logs in using the Bunq sandbox setup.
6. Seed demo data using `POST /demo/seed` if needed.
7. View transactions, receipts, goals, and dashboard data.

---

## Useful API Endpoints

### Health

```text
GET /health
```

### Authentication

```text
POST /auth/bunq/sandbox-login
GET /auth/me
```

### Demo

```text
POST /demo/seed
GET /demo/status
```

### Transactions

```text
GET /transactions/
GET /transactions/summary
GET /transactions/by-category
POST /bunq/transactions/sync
```

### Goals

```text
GET /goals/
POST /goals/
DELETE /goals/{goal_id}
```

### Receipts

```text
GET /receipts/
POST /receipts/
GET /receipts/{receipt_id}/detail
GET /receipts/match/candidates
POST /receipts/{receipt_id}/link-transaction/{transaction_id}
DELETE /receipts/{receipt_id}/unlink-transaction
DELETE /receipts/{receipt_id}
```

---

## Security Notes

Do not commit local secrets or generated credentials.

Do not commit:

```text
backend/.env
backend/.venv/
backend/.bunq_context/
*.pem
device_token.json
```

Recommended `.gitignore` entries:

```gitignore
.env
backend/.env
.venv/
backend/.venv/
backend/.bunq_context/
*.pem
device_token.json
```

---

## Troubleshooting

### Docker cannot connect

Make sure Docker Desktop is running.

Check:

```powershell
docker version
```

If the server section is missing or errors, restart Docker Desktop.

### Database tables are missing

Reset the database volume:

```powershell
docker compose down -v
docker compose up -d
```

### Flutter web cannot call backend

Make sure the backend is running at:

```text
http://127.0.0.1:8000
```

For Flutter web, do not use:

```text
http://10.0.2.2:8000
```

That address is only for Android emulator.

---

## Support

Have questions or suggestions? We would love to hear from you.

---

**Ranceipt — Your finances, simplified.**
