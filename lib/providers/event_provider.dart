import 'package:flutter/foundation.dart';
import '../models/event.dart';

class EventProvider with ChangeNotifier {
  Event? _currentEvent;
  int _checkedInCount = 0;

  Event? get currentEvent => _currentEvent;
  int get checkedInCount => _checkedInCount;

  int get remainingCapacity => (_currentEvent?.maxCapacity ?? 0) - _checkedInCount;

  bool get isFull => remainingCapacity <= 0;

  void setupEvent(Event event) {
    _currentEvent = event;
    _checkedInCount = 0;
    notifyListeners();
  }

  void updateCapacity(int checkedInCount) {
    _checkedInCount = checkedInCount;
    notifyListeners();
  }
}
