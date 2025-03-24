import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting.dart';
import 'package:intl/intl.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isCreatingMeeting = false;
  bool _isJoiningWithGoogle = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _getScheduledDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  // Create and join with Google authentication
  Future<void> _createAndJoinWithGoogle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isJoiningWithGoogle = true;
    });

    try {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.googleUser == null) {
        throw Exception('Bạn cần đăng nhập với Google trước');
      }

      // Create the meeting first
      debugPrint('Creating meeting with title: ${_titleController.text}');
      final meeting = await meetingProvider.createMeeting(
        title: _titleController.text,
        description: _descriptionController.text,
        scheduledTime: _getScheduledDateTime(),
      );

      debugPrint('Meeting created successfully with ID: ${meeting.meetingId}');

      if (!mounted) return;

      // Join with Google authentication
      debugPrint('Joining meeting with Google auth');
      await meetingProvider.joinMeetingWithGoogle(
        meetingId: meeting.meetingId,
        googleUser: authProvider.googleUser!,
      );

      debugPrint('Successfully joined meeting with Google auth');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error in create and join with Google: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningWithGoogle = false;
        });
      }
    }
  }

  // Create a regular meeting
  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingMeeting = true;
    });

    try {
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);

      debugPrint('Creating meeting with title: ${_titleController.text}');
      final meeting = await meetingProvider.createMeeting(
        title: _titleController.text,
        description: _descriptionController.text,
        scheduledTime: _getScheduledDateTime(),
      );

      debugPrint('Meeting created successfully with ID: ${meeting.meetingId}');

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cuộc họp đã được tạo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiêu đề: ${meeting.title}'),
              const SizedBox(height: 8),
              Text('ID cuộc họp: ${meeting.meetingId}'),
              const SizedBox(height: 8),
              Text('Thời gian: ${DateFormat('dd/MM/yyyy • HH:mm').format(meeting.startTime)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinMeeting(meeting.meetingId);
              },
              child: const Text('Tham gia ngay'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo cuộc họp: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingMeeting = false;
        });
      }
    }
  }

  // Join a meeting as a regular user
  Future<void> _joinMeeting(String meetingId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);

      debugPrint('Joining meeting with ID: $meetingId');
      await meetingProvider.joinMeeting(
        meetingId: meetingId,
        displayName: authProvider.userName ?? 'Guest',
        email: authProvider.userEmail,
        avatarUrl: authProvider.userAvatar,
      );

      debugPrint('Successfully joined meeting');
    } catch (e) {
      debugPrint('Error joining meeting: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tham gia cuộc họp: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo cuộc họp mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề cuộc họp',
                hintText: 'Nhập tiêu đề cho cuộc họp của bạn',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (Tùy chọn)',
                hintText: 'Nhập mô tả cho cuộc họp của bạn',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Date and Time
            Text(
              'Lịch trình',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày'),
              subtitle: Text(
                DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
              ),
              onTap: () => _selectDate(context),
            ),

            // Time picker
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Giờ'),
              subtitle: Text(
                _selectedTime.format(context),
              ),
              onTap: () => _selectTime(context),
            ),

            const SizedBox(height: 32),

            // Create button
            ElevatedButton(
              onPressed: _isCreatingMeeting || _isJoiningWithGoogle ? null : _createMeeting,
              child: _isCreatingMeeting
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
                  Text('Đang tạo cuộc họp...'),
                ],
              )
                  : const Text('Tạo cuộc họp'),
            ),

            const SizedBox(height: 16),

            // Create and join with Google button (only show if user is logged in with Google)
            if (authProvider.googleUser != null)
              ElevatedButton.icon(
                onPressed: _isCreatingMeeting || _isJoiningWithGoogle
                    ? null
                    : _createAndJoinWithGoogle,
                icon: _isJoiningWithGoogle
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata),
                ),
                label: _isJoiningWithGoogle
                    ? const Text('Đang kết nối với Google...')
                    : const Text('Tạo & tham gia với Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

