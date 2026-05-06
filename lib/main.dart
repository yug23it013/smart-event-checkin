import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/event_provider.dart';
import 'providers/participant_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/event_setup_screen.dart';
import 'screens/logs_screen.dart';

void main() {
  runApp(SmartEventCheckinApp());
}

class SmartEventCheckinApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => ParticipantProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Event Check-in',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/dashboard': (context) => DashboardScreen(),
          '/checkin': (context) => CheckinScreen(),
          '/event-setup': (context) => EventSetupScreen(),
          '/logs': (context) => LogsScreen(),
        },
      ),
    );
  }
}