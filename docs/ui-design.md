# UI/UX Design

## Screen List
- Splash
- Login (phone for students / email toggle for teacher-admin)
- OTP verification (students)
- Register (first-time students: name, class/grade, school)
- Student Dashboard (bottom nav: Learn, Games, Quiz, Profile)
  - Learn: subject list -> content list -> content viewer
  - Games: game list (placeholder, later sprint)
  - Quiz: quiz list -> quiz attempt -> result
  - Profile: student info, logout
- Teacher Dashboard: subjects, upload content, create quiz, student attempts
- Admin Dashboard: user management, subject management

## Color Palette (bright, child-friendly, high contrast)
- Primary: `#2F80ED` (sky blue)
- Secondary: `#F2C94C` (sunny yellow)
- Accent/Success: `#27AE60` (green)
- Error: `#EB5757` (red)
- Background: `#FFFFFF`
- Text: `#1A1A1A`
- Surface/cards: `#F5F8FF`

Chosen for strong contrast on low-end/cheap phone screens in bright outdoor light, and to feel playful rather than corporate.

## Typography
- Font: system default (Roboto on Android/Chrome) to keep app size small and avoid custom font licensing/loading cost.
- Headings: bold, 20–24sp.
- Body: regular, 16sp minimum (readability for children / low literacy).
- Buttons: bold, 16–18sp, all-caps avoided (easier reading for early readers).

## Wireframe Notes (per screen)
- **Splash**: centered logo + app name on primary color background, auto-navigates after JWT check.
- **Login**: large phone number field with country code, big "Send OTP" button; small text link "Login with email" for teacher/admin.
- **OTP**: 6 boxed digit inputs, countdown resend timer below, "Verify" button.
- **Register**: simple vertical form (name, class/grade dropdown, school name), "Continue" button.
- **Student Dashboard**: top app bar with subject/greeting, content area, bottom nav bar with 4 icons+labels (Learn/Games/Quiz/Profile) using secondary color highlight for active tab.
- **Teacher/Admin Dashboard**: simple list-style menu cards for each management action, no bottom nav (fewer, less frequent actions).
