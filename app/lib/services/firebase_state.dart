/// Set in main() after attempting Firebase.initializeApp().
/// Screens check this before using phone-OTP auth so the app never
/// crashes when Firebase hasn't been configured yet.
bool firebaseReady = false;
