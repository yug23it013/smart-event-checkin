import 'package:flutter/material.dart';

class LogsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Logs & Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Participant by ID or Name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // Search logic
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 0, // Update with participant count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Participant Name'),
                  subtitle: Text('Status: Checked-in | Time: 10:00 AM'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
