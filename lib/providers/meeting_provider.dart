import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/meeting.dart';
import '../services/database_service.dart';
import '../services/meeting_service.dart';

class MeetingProvider extends ChangeNotifier {
  final MeetingService _meetingService = MeetingService();

  List<Meeting> _meetings = [];
  Meeting? _currentMeeting;
  bool _isLoading = false;

  // Getters
  List<Meeting> get meetings => _meetings;
  Meeting? get currentMeeting => _currentMeeting;
  bool get isLoading => _isLoading;

  // Load all meetings
  Future<void> loadMeetings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _meetings = await DatabaseService.getAllMeetings();
      debugPrint('Loaded ${_meetings.length} meetings');
    } catch (e) {
      debugPrint('Error loading meetings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new meeting
  Future<Meeting> createMeeting({
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool isPasswordProtected = false,
    String? password,
    bool waitingRoomEnabled = false,
    bool recordingEnabled = false,
  }) async {
    try {
      final meeting = await _meetingService.createMeeting(
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        isPasswordProtected: isPasswordProtected,
        password: password,
        waitingRoomEnabled: waitingRoomEnabled,
        recordingEnabled: recordingEnabled,
      );

      _meetings.add(meeting);
      notifyListeners();

      return meeting;
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      throw Exception('Failed to create meeting: $e');
    }
  }

  // Join a meeting as a regular user
  Future<void> joinMeeting({
    required String meetingId,
    required String displayName,
    String? email,
    String? avatarUrl,
    bool audioMuted = false,
    bool videoMuted = false,
  }) async {
    try {
      debugPrint('Joining meeting: $meetingId as $displayName');
      await _meetingService.joinMeeting(
        meetingId: meetingId,
        displayName: displayName,
        email: email,
        avatarUrl: avatarUrl,
        audioMuted: audioMuted,
        videoMuted: videoMuted,
      );

      // Find or create meeting object
      try {
        _currentMeeting = await DatabaseService.getMeetingByMeetingId(meetingId);
        debugPrint('Found existing meeting in database');
      } catch (e) {
        debugPrint('Meeting not found in database, creating new entry');
        // Meeting not found, create a new one
        final newMeeting = Meeting()
          ..meetingId = meetingId
          ..title = 'Joined Meeting'
          ..startTime = DateTime.now()
          ..createdAt = DateTime.now();

        await DatabaseService.saveMeeting(newMeeting);
        _currentMeeting = newMeeting;
        _meetings.add(newMeeting);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error joining meeting: $e');
      throw Exception('Failed to join meeting: $e');
    }
  }

  // Join a meeting with Google account
  Future<void> joinMeetingWithGoogle({
    required String meetingId,
    required GoogleSignInAccount googleUser,
    bool audioMuted = false,
    bool videoMuted = false,
  }) async {
    try {
      debugPrint('Joining meeting with Google: $meetingId as ${googleUser.displayName}');
      await _meetingService.joinMeetingWithGoogle(
        meetingId: meetingId,
        googleUser: googleUser,
        audioMuted: audioMuted,
        videoMuted: videoMuted,
      );

      // Find or create meeting object
      try {
        _currentMeeting = await DatabaseService.getMeetingByMeetingId(meetingId);
        debugPrint('Found existing meeting in database');
      } catch (e) {
        debugPrint('Meeting not found in database, creating new entry');
        // Meeting not found, create a new one
        final newMeeting = Meeting()
          ..meetingId = meetingId
          ..title = 'Google Meeting'
          ..startTime = DateTime.now()
          ..createdAt = DateTime.now();

        await DatabaseService.saveMeeting(newMeeting);
        _currentMeeting = newMeeting;
        _meetings.add(newMeeting);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error joining meeting with Google: $e');
      throw Exception('Failed to join meeting with Google: $e');
    }
  }

  // Join a meeting with Jitsi's built-in Google authentication
  Future<bool> joinMeetingWithJitsiGoogleAuth({
    required String meetingId,
    bool audioMuted = false,
    bool videoMuted = false,
  }) async {
    try {
      debugPrint('Joining meeting with Jitsi Google Auth: $meetingId');
      final success = await _meetingService.joinMeetingWithJitsiGoogleAuth(
        meetingId: meetingId,
        audioMuted: audioMuted,
        videoMuted: videoMuted,
      );

      if (success) {
        // Find or create meeting object
        try {
          _currentMeeting = await DatabaseService.getMeetingByMeetingId(meetingId);
          debugPrint('Found existing meeting in database');
        } catch (e) {
          debugPrint('Meeting not found in database, creating new entry');
          // Meeting not found, create a new one
          final newMeeting = Meeting()
            ..meetingId = meetingId
            ..title = 'Jitsi Google Meeting'
            ..startTime = DateTime.now()
            ..createdAt = DateTime.now();

          await DatabaseService.saveMeeting(newMeeting);
          _currentMeeting = newMeeting;
          _meetings.add(newMeeting);
        }

        notifyListeners();
      }

      return success;
    } catch (e) {
      debugPrint('Error joining meeting with Jitsi Google Auth: $e');
      return false;
    }
  }

  // End the current meeting
  Future<void> endMeeting() async {
    try {
      await _meetingService.endMeeting();

      if (_currentMeeting != null) {
        _currentMeeting!.endTime = DateTime.now();
        await DatabaseService.saveMeeting(_currentMeeting!);
        _currentMeeting = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error ending meeting: $e');
      throw Exception('Failed to end meeting: $e');
    }
  }

  // Delete a meeting
  Future<void> deleteMeeting(int id) async {
    try {
      await DatabaseService.deleteMeeting(id);
      _meetings.removeWhere((meeting) => meeting.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meeting: $e');
      throw Exception('Failed to delete meeting: $e');
    }
  }

  // Share meeting details
  Future<void> shareMeeting(Meeting meeting) async {
    try {
      await _meetingService.shareMeeting(meeting);
    } catch (e) {
      debugPrint('Error sharing meeting: $e');
      throw Exception('Failed to share meeting: $e');
    }
  }
}

