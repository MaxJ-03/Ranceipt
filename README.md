Ranceipt

Smart Receipt Management & Spending Goals

Ranceipt is a smart receipt and spending management app that helps users understand their spending habits, track receipts, sync Bunq sandbox transactions, and manage personal saving goals.

This project is currently configured as a Bunq sandbox demo app.

The Idea

Ranceipt transforms the way you manage your spending. Instead of manually categorizing receipts or losing track of where your money goes, the app processes receipts, organizes purchases into categories, and helps users stay on track with personal financial goals.

Key Features
Smart Receipt Recognition — Capture receipts and process receipt data
Automatic Categorization — Organize receipt items into spending categories
Personal Spending Goals — Set and track saving/spending targets
Transaction Overview — View transactions and spending insights
Bunq Sandbox Integration — Sync transactions using Bunq sandbox users
Custom Categories — Use detailed product-level categories for receipt items
Demo Data Seeding — Populate the database with sample users, transactions, receipts, and goals
Tech Stack
Backend
Python
FastAPI
PostgreSQL
Docker Compose
Bunq Sandbox API
Frontend
Flutter
Dart
Prerequisites

Install the following before running the project:

Docker Desktop
Python 3.12+
Flutter
Git

Make sure Docker Desktop is running before starting the database.

Project Structure
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
Environment Setup

Create a .env file inside the backend/ folder:

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

Generate a token encryption key:

python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

Copy the generated value into:

TOKEN_ENCRYPTION_KEY=
Database Setup

From the backend folder, start Postgres:

cd backend
docker compose up -d

This starts a PostgreSQL container and initializes the database using:

ranceipt_db_init.sql

Check that the container is running:

docker ps

You should see a container named:

spending_postgres
Resetting the Database

If the database was already created before, the init SQL file will not run again automatically.

To reset the database:

docker compose down -v
docker compose up -d

Warning: this deletes all local database data.

Backend Setup

From the backend folder:

python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

Run the backend:

python -m uvicorn app.main:app --reload --reload-dir app

The backend runs at:

http://127.0.0.1:8000

API documentation:

http://127.0.0.1:8000/docs

Health check:

http://127.0.0.1:8000/health

Expected response:

{
  "status": "ok"
}
Demo Data

The project includes a demo seeding flow for local testing.

In Swagger, run:

POST /demo/seed

Then check the seeded data:

GET /demo/status

This populates the database with sample:

users
Bunq sandbox connection records
transactions
receipts
receipt items
saving goals
Bunq Sandbox Login

This project is configured for Bunq sandbox-only authentication.

The app does not use real Bunq OAuth in the demo setup.

The active login flow is:

POST /auth/bunq/sandbox-login

The backend uses:

BUNQ_SANDBOX_API_KEY=

to authenticate against the Bunq sandbox environment and create an internal app session.

The frontend then uses the returned session token for protected API requests.

Flutter Setup

Open a new terminal and go to the mobile folder:

cd mobile
flutter pub get

Run the app in Chrome:

flutter run -d chrome

For Flutter web, the backend base URL should be:

http://127.0.0.1:8000

For Android emulator, use:

http://10.0.2.2:8000
Recommended Local Run Order
Terminal 1: Database
cd backend
docker compose up -d
Terminal 2: Backend
cd backend
.\.venv\Scripts\Activate.ps1
python -m uvicorn app.main:app --reload --reload-dir app
Terminal 3: Flutter
cd mobile
flutter pub get
flutter run -d chrome
Demo Flow
Start Docker/Postgres.
Start the FastAPI backend.
Start the Flutter app.
Click Continue with bunq.
The app logs in using the Bunq sandbox setup.
Seed demo data using POST /demo/seed if needed.
View transactions, receipts, goals, and dashboard data.