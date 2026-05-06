import 'package:flutter/material.dart';
import 'checkin_screen.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Total Participants: 0', style: TextStyle(fontSize: 18)),
            Text('Checked-in: 0', style: TextStyle(fontSize: 18)),
            Text('Remaining Capacity: 0', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CheckinScreen())),
              child: Text('Go to Check-in'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LogsScreen())),
              child: Text('View Logs'),
            ),
          ],
        ),
      ),
    );
  }
}
