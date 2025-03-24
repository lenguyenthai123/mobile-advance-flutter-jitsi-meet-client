import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/meeting_card.dart';

class MeetingHistoryScreen extends StatefulWidget {
  const MeetingHistoryScreen({super.key});

  @override
  State<MeetingHistoryScreen> createState() => _MeetingHistoryScreenState();
}

class _MeetingHistoryScreenState extends State<MeetingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    await meetingProvider.loadMeetings();
  }

  @override
  Widget build(BuildContext context) {
    final meetingProvider = Provider.of<MeetingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting History'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMeetings,
        child: meetingProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : meetingProvider.meetings.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No meetings found. Create a meeting to get started.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: meetingProvider.meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = meetingProvider.meetings[index];
                      return MeetingCard(
                        meeting: meeting,
                        onJoin: () {
                          meetingProvider.joinMeeting(
                            meetingId: meeting.meetingId,
                            displayName: authProvider.userName ?? 'Guest',
                            email: authProvider.userEmail,
                            avatarUrl: authProvider.userAvatar,
                          );
                        },
                        onShare: () {
                          meetingProvider.shareMeeting(meeting);
                        },
                        onDelete: () async {
                          // Confirm deletion
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Meeting'),
                              content: Text(
                                'Are you sure you want to delete "${meeting.title}"?',
                              ),
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
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-meeting');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

