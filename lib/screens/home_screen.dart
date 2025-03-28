import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/create_meeting_screen.dart';
import '../screens/join_meeting_screen.dart';
import '../screens/login_screen.dart';
import '../screens/meeting_history_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/meeting_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    await meetingProvider.loadMeetings();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final meetingProvider = Provider.of<MeetingProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Near'),
        actions: [
          if (authProvider.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Quản trị',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message with admin badge if applicable
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Xin chào, ${authProvider.userName ?? 'Khách'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (authProvider.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Quản trị',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Admin login card (only show if not already an admin)
              if (!authProvider.isAdmin)
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quyền quản trị',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đăng nhập với Google để tạo cuộc họp với quyền quản trị và quản lý người dùng.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  );
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Đăng nhập với Google'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.video_call,
                      label: 'Tạo cuộc họp',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.add_box,
                      label: 'Tham gia',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const JoinMeetingScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Upcoming meetings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cuộc họp sắp tới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MeetingHistoryScreen()),
                      );
                    },
                    child: const Text('Xem tất cả'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Meeting list
              if (meetingProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (meetingProvider.meetings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Không có cuộc họp nào sắp tới. Tạo hoặc tham gia cuộc họp để bắt đầu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: meetingProvider.meetings.length > 3
                      ? 3
                      : meetingProvider.meetings.length,
                  itemBuilder: (context, index) {
                    final meeting = meetingProvider.meetings[index];
                    return MeetingCard(
                      meeting: meeting,
                      onJoin: () async {
                        try {
                          if (authProvider.googleUser != null) {
                            // Join with Google authentication
                            await meetingProvider.joinMeetingWithGoogle(
                              meetingId: meeting.meetingId,
                              googleUser: authProvider.googleUser!,
                            );
                          } else {
                            // Join as regular user
                            await meetingProvider.joinMeeting(
                              meetingId: meeting.meetingId,
                              displayName: authProvider.userName ?? 'Khách',
                              email: authProvider.userEmail,
                              avatarUrl: authProvider.userAvatar,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error joining meeting from card: $e');
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi tham gia cuộc họp: $e')),
                          );
                        }
                      },
                      onShare: () {
                        meetingProvider.shareMeeting(meeting);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
      }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

