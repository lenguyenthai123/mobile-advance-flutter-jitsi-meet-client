import '../models/meeting.dart';
import '../models/contact.dart';

class DatabaseService {
  // In-memory storage
  static final List<Meeting> _meetings = [];
  static final List<Contact> _contacts = [];
  static int _meetingIdCounter = 1;
  static int _contactIdCounter = 1;

  // Initialize service
  static Future<void> init() async {
    // No initialization needed for in-memory storage
    return;
  }

  // Meeting operations
  static Future<int> saveMeeting(Meeting meeting) async {
    if (meeting.id == 0) {
      // New meeting
      meeting.id = _meetingIdCounter++;
      _meetings.add(meeting);
    } else {
      // Update existing meeting
      final index = _meetings.indexWhere((m) => m.id == meeting.id);
      if (index >= 0) {
        _meetings[index] = meeting;
      } else {
        meeting.id = _meetingIdCounter++;
        _meetings.add(meeting);
      }
    }
    return meeting.id;
  }

  static Future<List<Meeting>> getAllMeetings() async {
    // Return a copy of the list sorted by start time (newest first)
    final meetings = List<Meeting>.from(_meetings);
    meetings.sort((a, b) => b.startTime.compareTo(a.startTime));
    return meetings;
  }

  static Future<Meeting?> getMeetingById(int id) async {
    return _meetings.firstWhere((m) => m.id == id, orElse: () => throw Exception('Meeting not found'));
  }

  static Future<Meeting?> getMeetingByMeetingId(String meetingId) async {
    return _meetings.firstWhere(
          (m) => m.meetingId == meetingId,
      orElse: () => throw Exception('Meeting not found'),
    );
  }

  static Future<bool> deleteMeeting(int id) async {
    final index = _meetings.indexWhere((m) => m.id == id);
    if (index >= 0) {
      _meetings.removeAt(index);
      return true;
    }
    return false;
  }

  // Contact operations
  static Future<int> saveContact(Contact contact) async {
    if (contact.id == 0) {
      // New contact
      contact.id = _contactIdCounter++;
      _contacts.add(contact);
    } else {
      // Update existing contact
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index >= 0) {
        _contacts[index] = contact;
      } else {
        contact.id = _contactIdCounter++;
        _contacts.add(contact);
      }
    }
    return contact.id;
  }

  static Future<List<Contact>> getAllContacts() async {
    // Return a copy of the list sorted by name (A-Z)
    final contacts = List<Contact>.from(_contacts);
    contacts.sort((a, b) => a.name.compareTo(b.name));
    return contacts;
  }

  static Future<Contact?> getContactById(int id) async {
    return _contacts.firstWhere((c) => c.id == id, orElse: () => throw Exception('Contact not found'));
  }

  static Future<Contact?> getContactByEmail(String email) async {
    return _contacts.firstWhere(
          (c) => c.email.toLowerCase() == email.toLowerCase(),
      orElse: () => throw Exception('Contact not found'),
    );
  }

  static Future<bool> deleteContact(int id) async {
    final index = _contacts.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _contacts.removeAt(index);
      return true;
    }
    return false;
  }

  // Close database - not needed for in-memory storage
  static Future<void> close() async {
    // No cleanup needed
    return;
  }
}

