class Event {
  String id;
  String name;
  DateTime date;
  int maxCapacity;

  Event({
    required this.id,
    required this.name,
    required this.date,
    required this.maxCapacity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'maxCapacity': maxCapacity,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      date: DateTime.parse(map['date']),
      maxCapacity: map['maxCapacity'],
    );
  }
}
