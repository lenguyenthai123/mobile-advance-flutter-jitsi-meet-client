import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';

class JoinMeetingScreen extends StatefulWidget {
  const JoinMeetingScreen({super.key});

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meetingIdController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _audioMuted = false;
  bool _videoMuted = false;
  bool _isJoining = false;
  bool _isJoiningWithGoogle = false;
  bool _joinAsAdmin = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userName != null) {
      _displayNameController.text = authProvider.userName!;
    }
  }

  @override
  void dispose() {
    _meetingIdController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Join as a regular user
  Future<void> _joinMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_joinAsAdmin && authProvider.googleUser != null) {
        // Join with Google authentication
        debugPrint('Joining meeting as admin with Google: ${_meetingIdController.text.trim()}');
        await meetingProvider.joinMeetingWithGoogle(
          meetingId: _meetingIdController.text.trim(),
          googleUser: authProvider.googleUser!,
          audioMuted: _audioMuted,
          videoMuted: _videoMuted,
        );
      } else {
        // Regular join
        debugPrint('Joining meeting as regular user: ${_meetingIdController.text.trim()}');
        await meetingProvider.joinMeeting(
          meetingId: _meetingIdController.text.trim(),
          displayName: _displayNameController.text.trim(),
          email: authProvider.userEmail,
          avatarUrl: authProvider.userAvatar,
          audioMuted: _audioMuted,
          videoMuted: _videoMuted,
        );
      }

      // Update user name if different
      if (authProvider.userName != _displayNameController.text.trim()) {
        await authProvider.updateProfile(
          name: _displayNameController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error joining meeting: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tham gia cuộc họp: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _isJoiningWithGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tham gia cuộc họp'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Meeting ID
            TextFormField(
              controller: _meetingIdController,
              decoration: InputDecoration(
                labelText: 'ID cuộc họp',
                hintText: 'Nhập ID cuộc họp',
                prefixIcon: const Icon(Icons.meeting_room),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  tooltip: 'Dán từ clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null && data.text != null) {
                      _meetingIdController.text = data.text!.trim();
                    }
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập ID cuộc họp';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Display Name
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị',
                hintText: 'Nhập tên hiển thị của bạn',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên của bạn';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Meeting options
            const Text(
              'Tùy chọn cuộc họp',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Audio muted
            SwitchListTile(
              title: const Text('Tắt âm thanh khi tham gia'),
              subtitle: const Text('Bạn có thể bật lại sau khi tham gia'),
              value: _audioMuted,
              onChanged: (value) {
                setState(() {
                  _audioMuted = value;
                });
              },
            ),

            // Video muted
            SwitchListTile(
              title: const Text('Tắt video khi tham gia'),
              subtitle: const Text('Bạn có thể bật lại sau khi tham gia'),
              value: _videoMuted,
              onChanged: (value) {
                setState(() {
                  _videoMuted = value;
                });
              },
            ),

            // Join as admin (only show if user is logged in with Google)
            if (authProvider.googleUser != null)
              SwitchListTile(
                title: const Text('Tham gia với quyền quản trị'),
                subtitle: const Text('Sử dụng tài khoản Google của bạn'),
                value: _joinAsAdmin,
                onChanged: (value) {
                  setState(() {
                    _joinAsAdmin = value;
                  });
                },
              ),

            const SizedBox(height: 32),

            // Join button
            ElevatedButton(
              onPressed: (_isJoining || _isJoiningWithGoogle) ? null : _joinMeeting,
              child: _isJoining || _isJoiningWithGoogle
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang tham gia...'),
                ],
              )
                  : Text(_joinAsAdmin && authProvider.googleUser != null
                  ? 'Tham gia với quyền quản trị'
                  : 'Tham gia cuộc họp'),
            ),
          ],
        ),
      ),
    );
  }
}

