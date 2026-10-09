# System Architecture

```mermaid
flowchart TB
    subgraph Device["Student Device (Flutter Web / later Android)"]
        App["Flutter App"]
        SQLite["SQLite (sqflite / sqflite_common_ffi_web)\noffline content, quizzes, pending attempts"]
        App <--> SQLite
    end

    subgraph Firebase["Firebase"]
        OTP["Phone Auth OTP"]
        FCM["Cloud Messaging (FCM)"]
    end

    subgraph Server["Backend Server (Docker)"]
        API["FastAPI (/api/v1)"]
        PG["PostgreSQL"]
        API <--> PG
    end

    App -- "phone OTP request" --> OTP
    OTP -- "Firebase ID token" --> App
    App -- "ID token -> /auth/otp-login" --> API
    API -- "JWT" --> App

    App -- "REST (content, quizzes, attempts) + JWT" --> API
    API -- "push notifications" --> FCM
    FCM -- "notify" --> App

    App -. "sync when online\n(pull content/quizzes, push pending_attempts)" .-> API
```

## Notes
- The Flutter app works offline-first: content, subjects, and quizzes are cached in on-device SQLite. Quiz attempts made offline are stored in `pending_attempts` and synced to the server once connectivity returns.
- Firebase handles phone OTP for students (and FCM for notifications, later sprint). The backend never talks to Firebase for OTP delivery — only to verify the ID token the app receives.
- The backend issues its own JWT after verifying the Firebase token (or email/password for teacher/admin), and all protected endpoints check that JWT plus role.
