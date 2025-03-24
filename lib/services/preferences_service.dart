import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  // Keys
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userAvatarKey = 'user_avatar';
  static const String _isDarkModeKey = 'is_dark_mode';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _isAdminKey = 'is_admin'; // Added admin key
  static const String _jwtTokenKey = 'jwt_token'; // Added JWT token key
  static const String _jitsiDomainKey = 'jitsi_domain'; // Added domain key
  static const String _savedUsernameKey = 'saved_username'; // Added saved username key
  static const String _savedDomainKey = 'saved_domain'; // Added saved domain key

  // Initialize shared preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // User preferences
  static String? getUserId() => _prefs.getString(_userIdKey);
  static Future<bool> setUserId(String userId) => _prefs.setString(_userIdKey, userId);

  static String? getUserName() => _prefs.getString(_userNameKey);
  static Future<bool> setUserName(String name) => _prefs.setString(_userNameKey, name);

  static String? getUserEmail() => _prefs.getString(_userEmailKey);
  static Future<bool> setUserEmail(String email) => _prefs.setString(_userEmailKey, email);

  static String? getUserAvatar() => _prefs.getString(_userAvatarKey);
  static Future<bool> setUserAvatar(String avatarUrl) => _prefs.setString(_userAvatarKey, avatarUrl);

  // App preferences
  static bool isDarkMode() => _prefs.getBool(_isDarkModeKey) ?? false;
  static Future<bool> setDarkMode(bool isDarkMode) => _prefs.setBool(_isDarkModeKey, isDarkMode);

  static bool isFirstLaunch() => _prefs.getBool(_isFirstLaunchKey) ?? true;
  static Future<bool> setFirstLaunch(bool isFirstLaunch) => _prefs.setBool(_isFirstLaunchKey, isFirstLaunch);

  // Admin preferences
  static bool isAdmin() => _prefs.getBool(_isAdminKey) ?? false;
  static Future<bool> setIsAdmin(bool isAdmin) => _prefs.setBool(_isAdminKey, isAdmin);

  // JWT token
  static String? getJwtToken() => _prefs.getString(_jwtTokenKey);
  static Future<bool> setJwtToken(String? token) {
    if (token == null) {
      return _prefs.remove(_jwtTokenKey);
    }
    return _prefs.setString(_jwtTokenKey, token);
  }

  // Jitsi domain
  static String? getJitsiDomain() => _prefs.getString(_jitsiDomainKey);
  static Future<bool> setJitsiDomain(String domain) => _prefs.setString(_jitsiDomainKey, domain);

  // Saved credentials
  static String? getSavedUsername() => _prefs.getString(_savedUsernameKey);
  static Future<bool> setSavedUsername(String? username) {
    if (username == null) {
      return _prefs.remove(_savedUsernameKey);
    }
    return _prefs.setString(_savedUsernameKey, username);
  }

  static String? getSavedDomain() => _prefs.getString(_savedDomainKey);
  static Future<bool> setSavedDomain(String? domain) {
    if (domain == null) {
      return _prefs.remove(_savedDomainKey);
    }
    return _prefs.setString(_savedDomainKey, domain);
  }

  // Clear all preferences
  static Future<bool> clearAll() => _prefs.clear();
}

