# Rural Edu Platform

A gamified learning platform for rural students. The project includes a Flutter web app for students, teachers, and administrators, plus a FastAPI backend for accounts, subjects, learning content, quizzes, and results.

## Features

- **Students:** browse subjects and learning content, take quizzes, and view quiz results and earned XP.
- **Teachers:** create and publish quizzes, upload learning content, and review quiz attempts.
- **Administrators:** access the platform administration dashboard.
- **Authentication:** Firebase phone OTP for students and email/password login for teachers and administrators.
- **Local development:** the backend uses SQLite by default, so you can run it without Docker or a separate database server.

## Tech stack

- **Frontend:** Flutter and Dart
- **Backend:** Python, FastAPI, SQLAlchemy, and Uvicorn
- **Database:** SQLite by default; PostgreSQL configuration is also included
- **Student phone authentication:** Firebase Authentication

## Prerequisites

- Windows PowerShell
- Python 3.12
- Flutter with Dart 3.13.5 or later
- Chrome or another modern browser

The commands below use the Flutter SDK location on the development machine (`C:\src\flutter`). If Flutter is already on your `PATH`, you can replace `& $Flutter` with `flutter`.

## Run locally

Run the backend and frontend in **separate PowerShell terminals**, starting in the repository root.

### 1. Install backend dependencies and start the API

Run this setup once (or again after backend requirements change):

```powershell
$Venv = Join-Path $env:LOCALAPPDATA 'skit-rural-edu-venv'
if (-not (Test-Path (Join-Path $Venv 'Scripts\python.exe'))) {
    py -3.12 -m venv $Venv
}
$Python = Join-Path $Venv 'Scripts\python.exe'
& $Python -m pip install -r .\backend\requirements.txt
```

In the backend terminal, start the API:

```powershell
$Python = Join-Path $env:LOCALAPPDATA 'skit-rural-edu-venv\Scripts\python.exe'
$env:PYTHONDONTWRITEBYTECODE = '1'
Push-Location .\backend
try {
    & $Python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
} finally {
    Pop-Location
}
```

The backend creates its database tables and adds demo users and sample learning data when it starts. With the default configuration, SQLite data is stored in `backend/rural_edu.db`.

### 2. Install frontend dependencies and start Flutter Web

In the second terminal:

```powershell
$Flutter = 'C:\src\flutter\bin\flutter.bat'
Push-Location .\app
try {
    & $Flutter pub get
    if ($LASTEXITCODE -eq 0) {
        & $Flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
    }
} finally {
    Pop-Location
}
```

Open the frontend at **http://127.0.0.1:8080**.

### 3. Check the backend

- Health check: **http://127.0.0.1:8000/health**
- Interactive API documentation: **http://127.0.0.1:8000/docs**

## Demo teacher and administrator accounts

Choose **“Login with email (teacher/admin)”** on the login screen:

| Role | Email | Password |
| --- | --- | --- |
| Teacher | `teacher@example.com` | `teacher123` |
| Administrator | `admin@example.com` | `admin123` |

These are development-only accounts seeded by the backend. Do not use these credentials or the default backend secrets in a deployed environment.

Student login uses Firebase phone authentication and may require a working Firebase project, phone-auth settings, an allowed web domain, and network access. The seeded student account uses phone number `+919876543210`; successful OTP delivery still depends on Firebase configuration.

## Run Flutter tests

```powershell
$Flutter = 'C:\src\flutter\bin\flutter.bat'
Push-Location .\app
try {
    & $Flutter test
} finally {
    Pop-Location
}
```

## Project layout

```text
app/                  Flutter application, web entry point, and tests
backend/app/          FastAPI application, database models, and API routers
backend/requirements.txt
                      Python dependencies
docs/architecture.md  Architecture overview
docker-compose.yml    PostgreSQL and backend container configuration
```

For more detail on the application flow and architecture, see [docs/architecture.md](docs/architecture.md).
