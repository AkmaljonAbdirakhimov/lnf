import 'package:flutter/material.dart';
import 'package:lnf/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.init();

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            LocalNotificationService.notificationsEnabled
                ? "Notifications Enabled!"
                : "Please enable notifications for the app in the settings.",
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            LocalNotificationService.showNotification(
              title: "Notification",
              body: "HELLO BODY",
            );
          },
          child: const Icon(Icons.notification_add),
        ),
      ),
    );
  }
}
