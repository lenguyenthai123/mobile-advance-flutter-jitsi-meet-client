import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Ensure we're signed out before attempting to sign in
      await _googleSignIn.signOut();

      // Trigger the Google Sign In process within the app
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in process
      if (googleUser == null) {
        debugPrint('Google Sign In: User cancelled the sign-in process');
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      debugPrint('Google Sign In: Successfully signed in as ${googleUser.displayName}');

      return googleUser;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  // Get the current user
  GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('Google Sign In: Successfully signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}

