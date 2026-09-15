import 'package:firebase_auth/firebase_auth.dart';

/// Turns raw Firebase/network errors into short, friendly messages
/// safe to show to students, instead of exposing error codes/stack traces.
String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      case 'invalid-verification-code':
      case 'code-expired':
        return 'That code is incorrect or expired. Please try again.';
      case 'internal-error':
        return 'Something went wrong starting verification. Please try again.';
      default:
        return 'Could not verify your phone. Please try again.';
    }
  }

  final text = error.toString();
  if (text.contains('not configured')) return 'Phone login is not available right now.';
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'No internet connection. Please check your network.';
  }
  return 'Something went wrong. Please try again.';
}
