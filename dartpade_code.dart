import 'package:flutter/material.dart';
import 'dart:math';
 
void main() {
  runApp(const MyApp());
}
 
// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────
 
class EventModel {
  final String id;
  final String name;
  final String venue;
  final DateTime dateTime;
  final int maxCapacity;
 
  EventModel({
    required this.id,
    required this.name,
    required this.venue,
    required this.dateTime,
    required this.maxCapacity,
  });
}
 
class ParticipantModel {
  final String id;
  final String name;
  final String eventId;
  bool isCheckedIn;
  DateTime? checkInTime;
  bool isSynced;
 
  ParticipantModel({
    required this.id,
    required this.name,
    required this.eventId,
    this.isCheckedIn = false,
    this.checkInTime,
    this.isSynced = false,
  });
}
 
class CheckInResult {
  final bool success;
  final String message;
  final ParticipantModel? participant;
  CheckInResult({required this.success, required this.message, this.participant});
}
 
// ─────────────────────────────────────────────
// APP STATE (Simple InheritedWidget-based)
// ─────────────────────────────────────────────
 
class AppState extends ChangeNotifier {
  EventModel? currentEvent;
  final List<EventModel> events = [];
  final List<ParticipantModel> participants = [];
  bool isOnline = true;
 
  List<ParticipantModel> get currentParticipants =>
      participants.where((p) => p.eventId == currentEvent?.id).toList();
 
  List<ParticipantModel> get checkedIn =>
      currentParticipants.where((p) => p.isCheckedIn).toList();
 
  int get totalCheckedIn => checkedIn.length;
  int get totalRegistered => currentParticipants.length;
  int get remainingCapacity => (currentEvent?.maxCapacity ?? 0) - totalCheckedIn;
 
  double get capacityPct =>
      currentEvent == null || currentEvent!.maxCapacity == 0
          ? 0
          : totalCheckedIn / currentEvent!.maxCapacity;
 
  String get crowdStatus {
    final p = capacityPct;
    if (p < 0.6) return 'Safe';
    if (p < 0.85) return 'Moderate';
    return 'Full';
  }
 
  void createEvent({
    required String name,
    required String venue,
    required DateTime dateTime,
    required int maxCapacity,
  }) {
    final event = EventModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      venue: venue,
      dateTime: dateTime,
      maxCapacity: maxCapacity,
    );
    events.add(event);
    currentEvent = event;
    _seedParticipants(event);
    notifyListeners();
  }
 
  void _seedParticipants(EventModel event) {
    final demos = [
      ['P001', 'Alice Johnson'],
      ['P002', 'Bob Smith'],
      ['P003', 'Charlie Brown'],
      ['P004', 'Diana Prince'],
      ['P005', 'Ethan Hunt'],
      ['P006', 'Fatima Malik'],
      ['P007', 'George Thomas'],
      ['P008', 'Hannah Lee'],
    ];
    for (final d in demos) {
      participants.add(ParticipantModel(id: d[0], name: d[1], eventId: event.id));
    }
  }
 
  void selectEvent(EventModel event) {
    currentEvent = event;
    notifyListeners();
  }
 
  CheckInResult checkIn(String pid) {
    if (currentEvent == null) {
      return CheckInResult(success: false, message: 'No active event!');
    }
    final p = currentParticipants.where((x) => x.id == pid).firstOrNull;
    if (p == null) {
      return CheckInResult(success: false, message: 'Participant "$pid" not found ❌');
    }
    if (p.isCheckedIn) {
      return CheckInResult(
          success: false,
          message: 'Already checked in at ${_fmt(p.checkInTime!)} ⚠️');
    }
    if (remainingCapacity <= 0) {
      return CheckInResult(success: false, message: 'Event at full capacity 🚫');
    }
    p.isCheckedIn = true;
    p.checkInTime = DateTime.now();
    p.isSynced = isOnline;
    notifyListeners();
    return CheckInResult(success: true, message: 'Welcome, ${p.name}! ✅', participant: p);
  }
 
  List<ParticipantModel> search(String q) {
    if (q.isEmpty) return currentParticipants;
    final lower = q.toLowerCase();
    return currentParticipants
        .where((p) => p.id.toLowerCase().contains(lower) || p.name.toLowerCase().contains(lower))
        .toList();
  }
 
  void toggleOnline() {
    isOnline = !isOnline;
    if (isOnline) {
      for (final p in participants.where((p) => !p.isSynced)) {
        p.isSynced = true;
      }
    }
    notifyListeners();
  }
 
  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
 
// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
 
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}
 
class _MyAppState extends State<MyApp> {
  final AppState _state = AppState();
 
  @override
  Widget build(BuildContext context) {
    return _AppStateProvider(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) => MaterialApp(
          title: 'Event Check-In',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
            useMaterial3: true,
          ),
          home: _state.currentEvent == null
              ? EventSetupScreen(state: _state)
              : MainShell(state: _state),
        ),
      ),
    );
  }
}
 
class _AppStateProvider extends InheritedWidget {
  final AppState state;
  const _AppStateProvider({required this.state, required super.child});
  @override
  bool updateShouldNotify(_AppStateProvider old) => true;
  static AppState of(BuildContext ctx) =>
      ctx.dependOnInheritedWidgetOfExactType<_AppStateProvider>()!.state;
}
 
// ─────────────────────────────────────────────
// MAIN SHELL with Bottom Navigation
// ─────────────────────────────────────────────
 
class MainShell extends StatefulWidget {
  final AppState state;
  const MainShell({super.key, required this.state});
  @override
  State<MainShell> createState() => _MainShellState();
}
 
class _MainShellState extends State<MainShell> {
  int _tab = 0;
 
  @override
  Widget build(BuildContext context) {
    final screens = [
      CheckInScreen(state: widget.state),
      DashboardScreen(state: widget.state),
      LogsScreen(state: widget.state),
    ];
 
    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF6C63FF).withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: Color(0xFF6C63FF)),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF6C63FF)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: Color(0xFF6C63FF)),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}
 
// ═══════════════════════════════════════════════════════
// SCREEN 1 — EVENT SETUP
// ═══════════════════════════════════════════════════════
 
class EventSetupScreen extends StatefulWidget {
  final AppState state;
  const EventSetupScreen({super.key, required this.state});
  @override
  State<EventSetupScreen> createState() => _EventSetupScreenState();
}
 
class _EventSetupScreenState extends State<EventSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
 
  @override
  void dispose() {
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }
 
  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }
 
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.state.createEvent(
      name: _nameCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      dateTime: DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
      maxCapacity: int.parse(_capCtrl.text.trim()),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: const Color(0xFF6C63FF),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Event Setup',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.event_available, size: 64, color: Colors.white24),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Past Events
                  if (widget.state.events.isNotEmpty) ...[
                    const Text('Existing Events',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.state.events.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final e = widget.state.events[i];
                          return GestureDetector(
                            onTap: () => widget.state.selectEvent(e),
                            child: Container(
                              width: 170,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text(e.venue,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  Text('Cap: ${e.maxCapacity}',
                                      style: const TextStyle(
                                          color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
 
                  const Text('Create New Event',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  const SizedBox(height: 14),
 
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _field(_nameCtrl, 'Event Name', Icons.celebration,
                                (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 14),
                            _field(_venueCtrl, 'Venue', Icons.location_on,
                                (v) => v!.isEmpty ? 'Required' : null),
                            const SizedBox(height: 14),
                            _field(_capCtrl, 'Max Capacity', Icons.people,
                                (v) {
                                  if (v!.isEmpty) return 'Required';
                                  if (int.tryParse(v) == null) return 'Enter a number';
                                  return null;
                                },
                                type: TextInputType.number),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _dtTile(
                                    '${_date.day}/${_date.month}/${_date.year}',
                                    Icons.calendar_today,
                                    'Date',
                                    _pickDate,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _dtTile(
                                    _time.format(context),
                                    Icons.access_time,
                                    'Time',
                                    _pickTime,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _submit,
                                icon: const Icon(Icons.rocket_launch),
                                label: const Text('Create & Start Event',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _field(TextEditingController ctrl, String label, IconData icon,
      String? Function(String?)? validator,
      {TextInputType? type}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
 
  Widget _dtTile(String value, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2D3142))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
 
// ═══════════════════════════════════════════════════════
// SCREEN 2 — CHECK-IN
// ═══════════════════════════════════════════════════════
 
class CheckInScreen extends StatefulWidget {
  final AppState state;
  const CheckInScreen({super.key, required this.state});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}
 
class _CheckInScreenState extends State<CheckInScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String? _lastMsg;
  bool? _lastSuccess;
  bool _simScanning = false;
  late AnimationController _anim;
  late Animation<double> _scale;
 
  final List<String> _demoIds = ['P001', 'P002', 'P003', 'P004', 'P005', 'P006', 'P007', 'P008'];
  int _demoIdx = 0;
 
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    _anim.dispose();
    super.dispose();
  }
 
  void _process(String id) {
    final result = widget.state.checkIn(id.trim().toUpperCase());
    setState(() {
      _lastMsg = result.message;
      _lastSuccess = result.success;
      _simScanning = false;
    });
    _anim.forward(from: 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
 
  void _simulateScan() {
    setState(() => _simScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final id = _demoIds[_demoIdx % _demoIds.length];
        _demoIdx++;
        _process(id);
      }
    });
  }
 
  void _manualCheckIn() {
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a Participant ID'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    _process(_ctrl.text);
    _ctrl.clear();
  }
 
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final event = s.currentEvent;
 
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Check-In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (event != null)
              Text(event.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: s.toggleOnline,
              child: Chip(
                avatar: Icon(s.isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 15, color: Colors.white),
                label: Text(s.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: s.isOnline ? Colors.green.shade600 : Colors.orange.shade700,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Event Banner
            if (event != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.name,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(event.venue,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${s.totalCheckedIn}/${event.maxCapacity}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
 
            // Feedback
            if (_lastMsg != null)
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: _lastSuccess! ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _lastSuccess! ? Colors.green.shade300 : Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastSuccess! ? Icons.check_circle : Icons.error,
                        color: _lastSuccess! ? Colors.green.shade700 : Colors.red.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_lastMsg!,
                            style: TextStyle(
                                color: _lastSuccess!
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
 
            // QR Section
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: Color(0xFF6C63FF)),
                        ),
                        const SizedBox(width: 12),
                        const Text('QR Code Scanner',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_simScanning) ...[
                      // Simulated scanner UI
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const _ScannerAnimation(),
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF6C63FF), width: 3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const Positioned(
                              bottom: 12,
                              child: Text('Scanning...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => setState(() => _simScanning = false),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _simulateScan,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Simulate QR Scan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('(Scans demo participants in order)',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
 
            // Manual Entry
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: Colors.green.shade700),
                        ),
                        const SizedBox(width: 12),
                        const Text('Manual Entry',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _manualCheckIn(),
                      decoration: InputDecoration(
                        labelText: 'Participant ID (e.g. P001)',
                        prefixIcon: const Icon(Icons.badge, color: Color(0xFF6C63FF)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _manualCheckIn,
                        icon: const Icon(Icons.how_to_reg),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: _demoIds
                          .map((id) => ActionChip(
                                label: Text(id, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  _ctrl.text = id;
                                },
                                backgroundColor: const Color(0xFFEDE7FF),
                                labelStyle: const TextStyle(color: Color(0xFF6C63FF)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
class _ScannerAnimation extends StatefulWidget {
  const _ScannerAnimation();
  @override
  State<_ScannerAnimation> createState() => _ScannerAnimationState();
}
 
class _ScannerAnimationState extends State<_ScannerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: -60, end: 60).animate(_ctrl);
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 140,
          height: 2,
          color: const Color(0xFF6C63FF).withOpacity(0.8),
        ),
      ),
    );
  }
}
 
// ═══════════════════════════════════════════════════════
// SCREEN 3 — DASHBOARD
// ═══════════════════════════════════════════════════════
 
class DashboardScreen extends StatelessWidget {
  final AppState state;
  const DashboardScreen({super.key, required this.state});
 
  @override
  Widget build(BuildContext context) {
    final s = state;
    final event = s.currentEvent;
    final pct = s.capacityPct;
    final status = s.crowdStatus;
 
    Color sc, bg;
    IconData si;
    switch (status) {
      case 'Safe':
        sc = Colors.green.shade700;
        bg = Colors.green.shade50;
        si = Icons.check_circle;
        break;
      case 'Moderate':
        sc = Colors.orange.shade700;
        bg = Colors.orange.shade50;
        si = Icons.warning_amber;
        break;
      default:
        sc = Colors.red.shade700;
        bg = Colors.red.shade50;
        si = Icons.dangerous;
    }
 
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        automaticallyImplyLeading: false,
        title: const Text('Live Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Banner
            if (event != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(event.venue,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const Spacer(),
                        const Icon(Icons.people, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text('Max: ${event.maxCapacity}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
 
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sc.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(si, color: sc, size: 36),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crowd Status',
                          style: TextStyle(color: sc.withOpacity(0.7), fontSize: 12)),
                      Text(status,
                          style: TextStyle(
                              color: sc, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Text('${(pct * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: sc, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 14),
 
            // Progress
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Capacity Fill',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 18,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(sc),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        Text('${event?.maxCapacity ?? 0}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
 
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _StatCard('Checked In', '${s.totalCheckedIn}',
                    Icons.how_to_reg, const Color(0xFF6C63FF), const Color(0xFFEDE7FF)),
                _StatCard('Remaining', '${s.remainingCapacity}',
                    Icons.event_seat, Colors.teal.shade700, Colors.teal.shade50),
                _StatCard('Registered', '${s.totalRegistered}',
                    Icons.people, Colors.blue.shade700, Colors.blue.shade50),
                _StatCard('Pending',
                    '${s.totalRegistered - s.totalCheckedIn}',
                    Icons.pending_actions, Colors.orange.shade700, Colors.orange.shade50),
              ],
            ),
            const SizedBox(height: 18),
 
            const Text('Recent Check-Ins',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 10),
 
            if (s.checkedIn.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No check-ins yet',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                    ],
                  ),
                ),
              )
            else
              ...s.checkedIn.reversed.take(8).map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                        child: Text(
                          p.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('ID: ${p.id}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (p.checkInTime != null)
                            Text(
                              '${p.checkInTime!.hour.toString().padLeft(2, '0')}:${p.checkInTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                            ),
                          if (!p.isSynced)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('Offline',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.orange.shade700)),
                            ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
 
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _StatCard(this.label, this.value, this.icon, this.color, this.bg);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ═══════════════════════════════════════════════════════
// SCREEN 4 — LOGS & SEARCH
// ═══════════════════════════════════════════════════════
 
class LogsScreen extends StatefulWidget {
  final AppState state;
  const LogsScreen({super.key, required this.state});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}
 
class _LogsScreenState extends State<LogsScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';
  late TabController _tabs;
 
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }
 
  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    var list = s.search(_query);
 
    if (_filter == 'Checked In') list = list.where((p) => p.isCheckedIn).toList();
    if (_filter == 'Pending') list = list.where((p) => !p.isCheckedIn).toList();
 
    list.sort((a, b) {
      if (a.isCheckedIn && !b.isCheckedIn) return -1;
      if (!a.isCheckedIn && b.isCheckedIn) return 1;
      if (a.checkInTime != null && b.checkInTime != null) {
        return b.checkInTime!.compareTo(a.checkInTime!);
      }
      return 0;
    });
 
    final logs = s.checkedIn.toList()
      ..sort((a, b) => b.checkInTime!.compareTo(a.checkInTime!));
 
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        automaticallyImplyLeading: false,
        title: const Text('Logs & Search',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Participants (${s.totalRegistered})'),
            Tab(text: 'Logs (${s.totalCheckedIn})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFF6C63FF), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Checked In', 'Pending'].map((f) {
                          final sel = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f),
                              selected: sel,
                              onSelected: (_) => setState(() => _filter = f),
                              selectedColor: const Color(0xFF6C63FF).withOpacity(0.15),
                              checkmarkColor: const Color(0xFF6C63FF),
                              labelStyle: TextStyle(
                                color: sel ? const Color(0xFF6C63FF) : Colors.grey.shade600,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Mini('Showing', '${list.length}', const Color(0xFF6C63FF)),
                        const SizedBox(width: 10),
                        _Mini('Checked In', '${s.totalCheckedIn}', Colors.green.shade700),
                        const SizedBox(width: 10),
                        _Mini('Pending', '${s.totalRegistered - s.totalCheckedIn}',
                            Colors.orange.shade700),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 52, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text('No results found',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final p = list[i];
                          final isIn = p.isCheckedIn;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    isIn ? Colors.green.shade100 : const Color(0xFFEDE7FF),
                                child: Text(
                                  p.name[0].toUpperCase(),
                                  style: TextStyle(
                                    color: isIn ? Colors.green.shade700 : const Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${p.id}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600, fontSize: 12)),
                                  if (p.checkInTime != null)
                                    Text(
                                      'Checked in at ${p.checkInTime!.hour.toString().padLeft(2, '0')}:${p.checkInTime!.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                          color: Colors.green.shade600, fontSize: 11),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isIn
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isIn ? '✓ In' : 'Pending',
                                  style: TextStyle(
                                    color: isIn
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
 
          // Tab 2: Timeline Logs
          logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 52, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('No check-ins yet',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final p = logs[i];
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6C63FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ),
                              if (i < logs.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFEDE7FF),
                                      child: Text(p.name[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: Color(0xFF6C63FF),
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Text('ID: ${p.id}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (p.checkInTime != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${p.checkInTime!.hour.toString().padLeft(2, '0')}:${p.checkInTime!.minute.toString().padLeft(2, '0')}',
                                            style: const TextStyle(
                                                color: Color(0xFF6C63FF),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15),
                                          ),
                                          if (!p.isSynced)
                                            Text('Offline',
                                                style: TextStyle(
                                                    color: Colors.orange.shade700,
                                                    fontSize: 11)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
 
class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Mini(this.label, this.value, this.color);
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}
