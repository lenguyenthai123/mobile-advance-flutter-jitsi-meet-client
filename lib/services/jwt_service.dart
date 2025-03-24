import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/preferences_service.dart';

class JwtService {
  // This would typically be stored securely or retrieved from a server
  // For demo purposes, we're hardcoding it here
  static const String _jwtSecret = 'your_jwt_secret_key';

  // Generate a JWT token for Jitsi Meet authentication
  static String generateJwtToken({
    required String username,
    required String domain,
    String? roomName,
    bool isAdmin = false,
    int expiresIn = 3600, // 1 hour by default
  }) {
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
          'name': username,
          'email': '$username@example.com', // Placeholder email
          'moderator': isAdmin,
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
  }

  // Verify a JWT token
  static bool verifyToken(String token) {
    try {
      final isExpired = JwtDecoder.isExpired(token);
      if (isExpired) {
        return false;
      }

      // In a real app, you would verify the signature here
      return true;
    } catch (e) {
      return false;
    }
  }

  // Save token to preferences
  static Future<void> saveToken(String token) async {
    await PreferencesService.setJwtToken(token);
  }

  // Get token from preferences
  static Future<String?> getToken() async {
    return PreferencesService.getJwtToken();
  }

  // Clear token from preferences
  static Future<void> clearToken() async {
    await PreferencesService.setJwtToken(null);
  }
}

