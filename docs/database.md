# Database Design

## ER Diagram (Server — PostgreSQL)

```mermaid
erDiagram
    USER {
        int id PK
        string name
        string phone
        string email
        string password_hash
        string role
        bool is_active
        datetime created_at
    }
    SUBJECT {
        int id PK
        string name
        datetime created_at
    }
    CONTENT {
        int id PK
        int subject_id FK
        string title
        string type
        string file_url
        int uploaded_by FK
        datetime updated_at
    }
    QUIZ {
        int id PK
        int subject_id FK
        string title
        int created_by FK
        datetime updated_at
    }
    QUESTION {
        int id PK
        int quiz_id FK
        string text
        json options
        int correct_option
    }
    ATTEMPT {
        int id PK
        int student_id FK
        int quiz_id FK
        int score
        datetime created_at
        datetime synced_at
    }

    SUBJECT ||--o{ CONTENT : has
    SUBJECT ||--o{ QUIZ : has
    QUIZ ||--o{ QUESTION : has
    USER ||--o{ CONTENT : uploads
    USER ||--o{ QUIZ : creates
    USER ||--o{ ATTEMPT : attempts
    QUIZ ||--o{ ATTEMPT : "attempted in"
```

## PostgreSQL (server) vs SQLite (device)
- **PostgreSQL** is the single source of truth: all users, subjects, content, quizzes, questions, and attempts live here. Managed via SQLAlchemy models + Alembic migrations (see `backend/app/models.py`, `backend/migrations/`).
- **SQLite** (see `docs/offline-schema.sql`) is a lightweight read-mostly cache on the student's device, holding only what's needed to learn and attempt quizzes offline (subjects, content, quizzes, questions), plus a `pending_attempts` table with a `synced` flag for attempts made while offline. The `updated_at` columns on the server let the device pull only what changed since its last sync; `pending_attempts` rows are pushed to `/attempts` and marked synced once the server confirms.
