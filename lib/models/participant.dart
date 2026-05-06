class Participant {
  String id;
  String name;
  bool isCheckedIn;
  DateTime? checkInTime;

  Participant({
    required this.id,
    required this.name,
    this.isCheckedIn = false,
    this.checkInTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isCheckedIn': isCheckedIn,
      'checkInTime': checkInTime?.toIso8601String(),
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      isCheckedIn: map['isCheckedIn'] ?? false,
      checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime']) : null,
    );
  }
}
