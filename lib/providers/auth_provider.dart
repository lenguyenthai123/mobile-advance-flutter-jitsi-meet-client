import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/preferences_service.dart';
import '../services/google_auth_service.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userAvatar;
  String? _jitsiDomain;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Getters
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userAvatar => _userAvatar;
  String? get jitsiDomain => _jitsiDomain;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;
  GoogleSignInAccount? get googleUser => _googleAuthService.getCurrentUser();

  // Initialize user data from preferences
  Future<void> initUser() async {
    _userId = PreferencesService.getUserId();
    _userName = PreferencesService.getUserName();
    _userEmail = PreferencesService.getUserEmail();
    _userAvatar = PreferencesService.getUserAvatar();
    _jitsiDomain = PreferencesService.getJitsiDomain() ?? 'meet.jit.si';
    _isAdmin = PreferencesService.isAdmin();

    _isAuthenticated = _userId != null;

    // Check if user is already signed in with Google
    if (_googleAuthService.isSignedIn()) {
      await _updateUserFromGoogle();
    }

    notifyListeners();
  }

  // Update user data from Google Sign In
  Future<void> _updateUserFromGoogle() async {
    final GoogleSignInAccount? googleUser = _googleAuthService.getCurrentUser();
    if (googleUser != null) {
      _userId = googleUser.id;
      _userName = googleUser.displayName;
      _userEmail = googleUser.email;
      _userAvatar = googleUser.photoUrl;
      _isAuthenticated = true;
      _isAdmin = true;

      // Save user data
      await PreferencesService.setUserId(_userId!);
      if (_userName != null) await PreferencesService.setUserName(_userName!);
      await PreferencesService.setUserEmail(_userEmail!);
      if (_userAvatar != null) await PreferencesService.setUserAvatar(_userAvatar!);
      await PreferencesService.setIsAdmin(true);
    }
  }

  // Create a guest user
  Future<void> createGuestUser(String name) async {
    final uuid = const Uuid();
    _userId = uuid.v4();
    _userName = name;
    _isAuthenticated = true;
    _isAdmin = false;

    await PreferencesService.setUserId(_userId!);
    await PreferencesService.setUserName(_userName!);
    await PreferencesService.setIsAdmin(false);

    notifyListeners();
  }

  // Set admin status
  Future<void> setAdmin(bool isAdmin) async {
    _isAdmin = isAdmin;
    await PreferencesService.setIsAdmin(isAdmin);
    notifyListeners();
  }

  // Login with Google
  Future<bool> loginWithGoogle({String? domain}) async {
    try {
      debugPrint('Starting Google Sign In process...');

      // Set default domain if not provided
      if (domain != null && domain.isNotEmpty) {
        _jitsiDomain = domain;
        await PreferencesService.setJitsiDomain(domain);
        await PreferencesService.setSavedDomain(domain);
        debugPrint('Domain set to: $domain');
      } else {
        _jitsiDomain = 'meet.jit.si';
        await PreferencesService.setJitsiDomain(_jitsiDomain!);
        debugPrint('Using default domain: $_jitsiDomain');
      }

      // Attempt to sign in with Google
      final GoogleSignInAccount? googleUser = await _googleAuthService.signIn();

      if (googleUser != null) {
        debugPrint('Google Sign In successful: ${googleUser.displayName}');

        _userId = googleUser.id;
        _userName = googleUser.displayName;
        _userEmail = googleUser.email;
        _userAvatar = googleUser.photoUrl;
        _isAuthenticated = true;
        _isAdmin = true;

        // Save user data
        await PreferencesService.setUserId(_userId!);
        if (_userName != null) await PreferencesService.setUserName(_userName!);
        await PreferencesService.setUserEmail(_userEmail!);
        if (_userAvatar != null) await PreferencesService.setUserAvatar(_userAvatar!);
        await PreferencesService.setIsAdmin(true);

        notifyListeners();
        return true;
      } else {
        debugPrint('Google Sign In failed or was cancelled by user');
        return false;
      }
    } catch (e) {
      debugPrint('Error during Google Sign In: $e');
      return false;
    }
  }

  // Get saved domain
  Future<String?> getSavedDomain() async {
    return PreferencesService.getSavedDomain() ?? 'meet.jit.si';
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    if (name != null) {
      _userName = name;
      await PreferencesService.setUserName(name);
    }

    if (email != null) {
      _userEmail = email;
      await PreferencesService.setUserEmail(email);
    }

    if (avatarUrl != null) {
      _userAvatar = avatarUrl;
      await PreferencesService.setUserAvatar(avatarUrl);
    }

    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    // Sign out from Google if signed in
    if (_googleAuthService.isSignedIn()) {
      await _googleAuthService.signOut();
    }

    _isAuthenticated = false;
    _isAdmin = false;

    // Clear admin status
    await PreferencesService.setIsAdmin(false);

    notifyListeners();
  }
}

