import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../screens/home_screen.dart';
import '../services/preferences_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController(text: 'meet.jit.si');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedDomain();
  }

  Future<void> _loadSavedDomain() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final savedDomain = await authProvider.getSavedDomain();

    if (savedDomain != null) {
      _domainController.text = savedDomain;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  // Login with Jitsi's built-in Google authentication
  Future<void> _loginWithJitsiGoogleAuth() async {
    if (_domainController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên miền Jitsi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);

      // Save domain
      final domain = _domainController.text.trim();
      await PreferencesService.setJitsiDomain(domain);
      await PreferencesService.setSavedDomain(domain);

      // Create a temporary meeting ID for authentication
      final tempMeetingId = 'auth_${DateTime.now().millisecondsSinceEpoch}';

      // Join with Jitsi's built-in Google authentication
      debugPrint('Authenticating with Jitsi Google Auth using domain: $domain');
      final success = await meetingProvider.joinMeetingWithJitsiGoogleAuth(
        meetingId: tempMeetingId,
      );

      if (success) {
        debugPrint('Successfully authenticated with Jitsi Google Auth');

        // Set user as admin
        await authProvider.setAdmin(true);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công! Bạn đã có quyền quản trị.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        debugPrint('Failed to authenticate with Jitsi Google Auth');
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thất bại hoặc bị hủy. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during Jitsi Google Auth: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đăng nhập: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pop(); // Just go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập quản trị'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and title
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đăng nhập quản trị',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng nhập với Google để truy cập tính năng quản trị',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Domain field
                  TextFormField(
                    controller: _domainController,
                    decoration: const InputDecoration(
                      labelText: 'Tên miền Jitsi',
                      hintText: 'Nhập tên miền máy chủ Jitsi của bạn',
                      prefixIcon: Icon(Icons.dns),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên miền Jitsi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Google Sign In button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loginWithJitsiGoogleAuth,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black54,
                      ),
                    )
                        : Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata),
                    ),
                    label: _isLoading
                        ? const Text('Đang đăng nhập...')
                        : const Text('Đăng nhập với Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cancel button
                  OutlinedButton(
                    onPressed: _continueAsGuest,
                    child: const Text('Hủy'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

