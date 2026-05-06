import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import 'event_provider.dart';

class ParticipantProvider with ChangeNotifier {
  final List<Participant> _participants = [];

  List<Participant> get participants => _participants;

  int get totalParticipants => _participants.length;
  int get checkedInCount => _participants.where((p) => p.isCheckedIn).length;

  void addParticipant(Participant participant) {
    if (!_participants.any((p) => p.id == participant.id)) {
      _participants.add(participant);
      notifyListeners();
    }
  }

  String checkInParticipant(String id, EventProvider eventProvider) {
    if (eventProvider.currentEvent == null) {
      return 'No event setup found.';
    }

    if (eventProvider.remainingCapacity <= 0) {
      return 'Event is at full capacity.';
    }

    var existingIndex = _participants.indexWhere((p) => p.id == id);
    
    if (existingIndex != -1) {
      if (_participants[existingIndex].isCheckedIn) {
        return 'Participant already checked in (Duplicate).';
      }
      _participants[existingIndex].isCheckedIn = true;
      _participants[existingIndex].checkInTime = DateTime.now();
    } else {
      _participants.add(Participant(
        id: id,
        name: 'Participant $id',
        isCheckedIn: true,
        checkInTime: DateTime.now(),
      ));
    }

    // Notify event provider to update remaining capacity, though if we manage state properly, we can just notify listeners
    eventProvider.updateCapacity(checkedInCount);
    notifyListeners();
    return 'Success';
  }

  List<Participant> searchParticipants(String query) {
    if (query.isEmpty) return _participants;
    return _participants.where((p) => 
      p.id.contains(query) || p.name.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  void clearParticipants() {
    _participants.clear();
    notifyListeners();
  }
}
