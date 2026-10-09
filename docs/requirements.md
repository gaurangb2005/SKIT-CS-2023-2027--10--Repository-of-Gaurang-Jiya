# Requirements

## Functional Requirements

### Admin
- Log in with email + password.
- Create, activate, and deactivate Teacher accounts.
- View list of all users (students, teachers).
- Create and manage subjects.

### Teacher
- Log in with email + password.
- Upload learning content (text/PDF/video link) under a subject.
- Create quizzes with multiple-choice questions for a subject.
- View student quiz attempts and scores.

### Student
- Register with name, class/grade, school on first login.
- Log in via phone number + OTP (Firebase).
- Browse subjects and learning content, available offline after first sync.
- Play subject-linked games (later sprint).
- Attempt quizzes; attempts sync to server when online.

## Non-Functional Requirements
- App must work with no/poor internet connectivity (offline-first on device via SQLite, sync when online).
- UI must be usable on low-end Android phones and in Chrome (bright colors, large touch targets, minimal text).
- Backend must run in Docker for easy deployment on low-resource servers.
- Auth tokens (JWT) expire and are role-checked on every protected endpoint.
- Student phone numbers and personal data are not exposed to other students.
