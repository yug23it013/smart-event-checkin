import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class EventSetupScreen extends StatefulWidget {
  @override
  _EventSetupScreenState createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends State<EventSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _eventName = '';
  DateTime? _eventDate;
  int _maxCapacity = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Event Setup')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Event Name'),
                onSaved: (value) => _eventName = value ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Max Capacity'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _maxCapacity = int.tryParse(value ?? '0') ?? 0,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Setup event via Provider here
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardScreen()),
                    );
                  }
                },
                child: Text('Create Event'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
