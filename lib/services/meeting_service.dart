import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../models/meeting.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

class MeetingService {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  final Uuid _uuid = const Uuid();

  // Generate a unique meeting ID
  String generateMeetingId() {
    return _uuid.v4().substring(0, 8);
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
      debugPrint('Joining meeting as regular user: $meetingId');
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://meet.jit.si',
        room: meetingId,
        configOverrides: {
          'startWithAudioMuted': audioMuted,
          'startWithVideoMuted': videoMuted,
          'prejoinPageEnabled': false,
        },
        featureFlags: {
          'pip.enabled': true,
          'chat.enabled': true,
          'invite.enabled': true,
          'raise-hand.enabled': true,
          'tile-view.enabled': true,
          'toolbox.enabled': true,
          'filmstrip.enabled': true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
          email: email,
          avatar: avatarUrl,
        ),
      );

      await _jitsiMeet.join(options);
      debugPrint('Successfully joined meeting as regular user');
    } catch (e) {
      debugPrint('Error joining meeting: $e');
      throw Exception('Failed to join meeting: $e');
    }
  }

  // Join a meeting with Google authentication
  Future<void> joinMeetingWithGoogle({
    required String meetingId,
    required GoogleSignInAccount googleUser,
    bool audioMuted = false,
    bool videoMuted = false,
  }) async {
    try {
      debugPrint('Joining meeting with Google auth: $meetingId');
      final domain = PreferencesService.getJitsiDomain() ?? 'meet.jit.si';

      // Use Jitsi's built-in Google authentication
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://$domain',
        room: meetingId,
        token: await googleUser.authentication.then((auth) => auth.accessToken),
        configOverrides: {
          'startWithAudioMuted': audioMuted,
          'startWithVideoMuted': videoMuted,
          'prejoinPageEnabled': false,
          'disableDeepLinking': true,
          // Enable Google authentication
          'googleApiApplicationClientID': '39065779381-rfl8k52eab7i7flkfcg29ql4uiv0j0kc.apps.googleusercontent.com',
        },
        featureFlags: {
          'pip.enabled': true,
          'chat.enabled': true,
          'invite.enabled': true,
          'recording.enabled': true,
          'live-streaming.enabled': true,
          'raise-hand.enabled': true,
          'overflow-menu.enabled': true,
          'meeting-password.enabled': true,
          'kick-out.enabled': true,
          'lobby-mode.enabled': true,
          // Enable Google authentication
          'google-auth.enabled': true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: googleUser.displayName ?? 'Google User',
          email: googleUser.email,
          avatar: googleUser.photoUrl,
        ),
      );

      await _jitsiMeet.join(options);
      debugPrint('Successfully joined meeting with Google auth');
    } catch (e) {
      debugPrint('Error joining meeting with Google: $e');
      throw Exception('Failed to join meeting with Google: $e');
    }
  }

  // Create and save a meeting
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
      debugPrint('Creating new meeting');
      final meetingId = generateMeetingId();
      final meeting = Meeting()
        ..meetingId = meetingId
        ..title = title ?? 'New Meeting'
        ..description = description
        ..startTime = scheduledTime ?? DateTime.now()
        ..createdAt = DateTime.now()
        ..passwordProtected = isPasswordProtected
        ..password = password
        ..waitingRoomEnabled = waitingRoomEnabled
        ..recordingEnabled = recordingEnabled;

      final id = await DatabaseService.saveMeeting(meeting);
      meeting.id = id;

      debugPrint('Meeting created with ID: $meetingId');
      return meeting;
    } catch (e) {
      debugPrint('Error creating meeting: $e');
      throw Exception('Failed to create meeting: $e');
    }
  }

  // Join a meeting directly with Jitsi's built-in Google authentication
  Future<bool> joinMeetingWithJitsiGoogleAuth({
    required String meetingId,
    bool audioMuted = false,
    bool videoMuted = false,
  }) async {
    try {
      debugPrint('Joining meeting with Jitsi Google Auth: $meetingId');
      final domain = PreferencesService.getJitsiDomain() ?? 'meet.jit.si';

      // Use Jitsi's built-in Google authentication
      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://$domain',
        room: meetingId,
        configOverrides: {
          'startWithAudioMuted': audioMuted,
          'startWithVideoMuted': videoMuted,
          'prejoinPageEnabled': false,
        },
        featureFlags: {
          'pip.enabled': true,
          'chat.enabled': true,
          'invite.enabled': true,
          'recording.enabled': true,
          'live-streaming.enabled': true,
          'raise-hand.enabled': true,
          // Enable Google authentication
          'google-auth.enabled': true,
        },
      );

      // Set up event listeners
      _jitsiMeet.eventListener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint('Conference joined: $url');
        },
        conferenceTerminated: (url, error) {
          debugPrint('Conference terminated: $url, error: $error');
        },
      );

      await _jitsiMeet.join(options);
      debugPrint('Successfully initiated Jitsi with Google Auth');
      return true;
    } catch (e) {
      debugPrint('Error joining meeting with Jitsi Google Auth: $e');
      return false;
    }
  }

  // Share meeting details
  Future<void> shareMeeting(Meeting meeting) async {
    try {
      final meetingLink = 'https://meet.jit.si/${meeting.meetingId}';
      final shareText = '''
Tham gia cuộc họp của tôi trên Near
Tiêu đề: ${meeting.title}
Thời gian: ${meeting.startTime.toString()}
Link: $meetingLink
${meeting.passwordProtected ? 'Mật khẩu: ${meeting.password}' : ''}
''';

      await Share.share(shareText, subject: 'Tham gia cuộc họp Near của tôi');
    } catch (e) {
      debugPrint('Error sharing meeting: $e');
      throw Exception('Failed to share meeting: $e');
    }
  }

  // End the current meeting
  Future<void> endMeeting() async {
    try {
      await _jitsiMeet.hangUp();
    } catch (e) {
      debugPrint('Error ending meeting: $e');
      throw Exception('Failed to end meeting: $e');
    }
  }
}

