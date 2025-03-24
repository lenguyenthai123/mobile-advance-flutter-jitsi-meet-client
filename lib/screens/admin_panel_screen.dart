import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      await meetingProvider.loadMeetings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final meetingProvider = Provider.of<MeetingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meetings'),
            Tab(text: 'Users'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          // Meetings Tab
          _buildMeetingsTab(meetingProvider),

          // Users Tab
          _buildUsersTab(),

          // Settings Tab
          _buildSettingsTab(authProvider),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-meeting');
        },
        child: const Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildMeetingsTab(MeetingProvider meetingProvider) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: meetingProvider.meetings.isEmpty
          ? const Center(
        child: Text('No meetings found'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meetingProvider.meetings.length,
        itemBuilder: (context, index) {
          final meeting = meetingProvider.meetings[index];
          return _buildMeetingItem(meeting);
        },
      ),
    );
  }

  Widget _buildMeetingItem(Meeting meeting) {
    final theme = Theme.of(context);
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meeting.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusBadge(meeting),
              ],
            ),
            const SizedBox(height: 8),
            if (meeting.description != null && meeting.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(meeting.description!),
              ),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(meeting.startTime),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.meeting_room, size: 16),
                const SizedBox(width: 4),
                Text(
                  'ID: ${meeting.meetingId}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Meeting'),
                        content: Text('Are you sure you want to delete "${meeting.title}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await meetingProvider.deleteMeeting(meeting.id);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implement edit meeting
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit meeting feature coming soon')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join as Admin'),
                  onPressed: () {
                    if (authProvider.googleUser != null) {
                      meetingProvider.joinMeetingWithGoogle(
                        meetingId: meeting.meetingId,
                        googleUser: authProvider.googleUser!,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bạn cần đăng nhập với Google để tham gia với quyền quản trị'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Meeting meeting) {
    final now = DateTime.now();
    final isUpcoming = meeting.startTime.isAfter(now);
    final isActive = meeting.startTime.isBefore(now) &&
        (meeting.endTime == null || meeting.endTime!.isAfter(now));

    Color color;
    String text;

    if (isActive) {
      color = Colors.green;
      text = 'Active';
    } else if (isUpcoming) {
      color = Colors.orange;
      text = 'Upcoming';
    } else {
      color = Colors.grey;
      text = 'Completed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    // Placeholder for users tab
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'User Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This feature is coming soon',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User management feature coming soon')),
              );
            },
            child: const Text('Manage Users'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AuthProvider authProvider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Server Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Jitsi Domain'),
                  subtitle: Text(authProvider.jitsiDomain ?? 'Not set'),
                  leading: const Icon(Icons.dns),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    // TODO: Implement domain editing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Domain editing feature coming soon')),
                    );
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Enable Recording'),
                  subtitle: const Text('Allow meeting recordings'),
                  value: true, // Placeholder value
                  onChanged: (value) {
                    // TODO: Implement recording toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recording settings feature coming soon')),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Enable Waiting Room'),
                  subtitle: const Text('Participants must be admitted by a moderator'),
                  value: true, // Placeholder value
                  onChanged: (value) {
                    // TODO: Implement waiting room toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waiting room settings feature coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Require Password for All Meetings'),
                  subtitle: const Text('Automatically generate passwords for new meetings'),
                  value: false, // Placeholder value
                  onChanged: (value) {
                    // TODO: Implement password requirement toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password settings feature coming soon')),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Only Authenticated Users Can Join'),
                  subtitle: const Text('Require users to sign in before joining meetings'),
                  value: false, // Placeholder value
                  onChanged: (value) {
                    // TODO: Implement authentication requirement toggle
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Authentication settings feature coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await authProvider.signOut();

              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Sign Out'),
        ),
      ],
    );
  }
}

