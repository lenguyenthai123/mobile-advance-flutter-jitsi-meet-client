import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';

class JitsiTokenService {
  // This would typically be stored securely or retrieved from a server
  // For demo purposes, we're hardcoding it here
  static const String _jwtSecret = 'your_jwt_secret_key';

  // Generate a JWT token for Jitsi Meet using Google credentials
  String generateJwtTokenFromGoogle({
    required GoogleSignInAccount googleUser,
    required String domain,
    String? roomName,
    bool isAdmin = true,
    int expiresIn = 3600, // 1 hour by default
  }) {
    try {
      // Get user details from Google Sign In
      final String displayName = googleUser.displayName ?? 'Google User';
      final String email = googleUser.email;
      final String photoURL = googleUser.photoUrl ?? '';

      // Create JWT token
      final now = DateTime.now();
      final expiryTime = now.add(Duration(seconds: expiresIn));

      // Create header
      final header = {
        'alg': 'HS256',
        'typ': 'JWT'
      };

      // Create payload
      final payload = {
        'iss': 'near_app', // Issuer
        'aud': domain, // Audience (Jitsi domain)
        'sub': domain, // Subject
        'exp': expiryTime.millisecondsSinceEpoch ~/ 1000, // Expiry time in seconds
        'iat': now.millisecondsSinceEpoch ~/ 1000, // Issued at time in seconds
        'nbf': now.millisecondsSinceEpoch ~/ 1000, // Not before time in seconds
        'context': {
          'user': {
            'name': displayName,
            'email': email,
            'avatar': photoURL,
            'moderator': isAdmin,
            'id': googleUser.id,
          },
          'features': {
            'livestreaming': isAdmin,
            'recording': isAdmin,
            'outbound-call': isAdmin,
            'transcription': isAdmin,
            'lobby-bypass': isAdmin,
          },
        },
        'room': roomName,
      };

      // Encode header and payload
      final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));
      final encodedPayload = base64Url.encode(utf8.encode(json.encode(payload)));

      // Create signature
      final signatureInput = '$encodedHeader.$encodedPayload';
      final hmac = Hmac(sha256, utf8.encode(_jwtSecret));
      final digest = hmac.convert(utf8.encode(signatureInput));
      final signature = base64Url.encode(digest.bytes);

      // Combine to form JWT token
      return '$encodedHeader.$encodedPayload.$signature';
    } catch (e) {
      print('Error generating JWT token: $e');
      throw Exception('Failed to generate JWT token: $e');
    }
  }

  // In a real-world application, you would have a server endpoint that generates the JWT token
  // This is a more secure approach as it keeps your JWT secret on the server
  Future<String> getJwtTokenFromServer({
    required String googleIdToken,
    required String domain,
    String? roomName,
  }) async {
    // This is a placeholder for a real API call to your backend
    // Your backend would verify the Google ID token and generate a JWT token for Jitsi

    // For demo purposes, we'll just return a dummy token
    return 'dummy_jwt_token_from_server';
  }
}

