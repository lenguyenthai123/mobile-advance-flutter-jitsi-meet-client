class Meeting {
  int id = 0;
  late String meetingId;
  late String title;
  String? description;
  late DateTime startTime;
  DateTime? endTime;
  late DateTime createdAt;
  List<String> participants = [];
  bool isRecurring = false;
  String? recurrencePattern;

  // Meeting settings
  bool passwordProtected = false;
  String? password;
  bool waitingRoomEnabled = false;
  bool recordingEnabled = false;
}

