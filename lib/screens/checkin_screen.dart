import 'package:flutter/material.dart';

class CheckinScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check-in Participant')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // QR Scanner Logic
              },
              child: Text('Scan QR Code'),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: TextField(
                decoration: InputDecoration(labelText: 'Manual Entry (ID)'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Manual Checkin Logic
              },
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
