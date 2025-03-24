import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meeting.dart';

class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onJoin;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onJoin,
    required this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isUpcoming = meeting.startTime.isAfter(now);
    final isActive = meeting.startTime.isBefore(now) &&
        (meeting.endTime == null || meeting.endTime!.isAfter(now));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting status
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? Colors.green
                        : (isUpcoming ? Colors.orange : Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive
                      ? 'Active'
                      : (isUpcoming ? 'Upcoming' : 'Completed'),
                  style: TextStyle(
                    color: isActive
                        ? Colors.green
                        : (isUpcoming ? Colors.orange : Colors.grey),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Meeting ID
                Text(
                  'ID: ${meeting.meetingId}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Meeting title
            Text(
              meeting.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (meeting.description != null && meeting.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                meeting.description!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),

            // Meeting time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(meeting.startTime),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: onShare,
                  tooltip: 'Share',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join'),
                  onPressed: onJoin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

