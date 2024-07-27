import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MinimalFastingTrackerApp());
}

class MinimalFastingTrackerApp extends StatelessWidget {
  const MinimalFastingTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Fasting Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const FastingHomePage(),
    );
  }
}

class FastingHomePage extends StatefulWidget {
  const FastingHomePage({super.key});

  @override
  State<FastingHomePage> createState() => _FastingHomePageState();
}

class _FastingHomePageState extends State<FastingHomePage> {
  DateTime? startTime;
  DateTime? endTime;
  List<String> fastingHistory = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadFastingHistory();
    _initNotifications();
  }

  void _initNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'fasting_tracker_nofitication', 'Fasting Start/End Notifications',
      importance: Importance.max, priority: Priority.high, showWhen: false);
    const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  void _loadFastingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fastingHistory = prefs.getStringList('fastingHistory') ?? [];
    });
  }

  void _saveFastingHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('fastingHistory', fastingHistory);
  }

  void startFasting() {
    setState(() {
      startTime = DateTime.now();
      endTime = null;
    });
    _showNotification('Fasting started', 'Your fasting period has begun');
  }

  void stopFasting() {
    setState(() {
      endTime = DateTime.now();
      if (startTime != null) {
        fastingHistory.add('Started: ${startTime.toString()}, Ended: ${endTime.toString()}');
        startTime = null;
        _saveFastingHistory();
      }
    });
    _showNotification('Fasting ended', 'Your fasting period has ended');
  }

  Duration _calculateLongestFast() {
    Duration longest = Duration.zero;
    for (var entry in fastingHistory) {
      var parts = entry.split(', ');
      var start = DateTime.parse(parts[0].split(': ')[1]);
      var end = DateTime.parse(parts[1].split(': ')[1]);
      var duration = end.difference(start);
      if (duration > longest) {
        longest = duration;
      }
    }
    return longest;
  }

  Duration _calculateAverageFast() {
    if (fastingHistory.isEmpty) return Duration.zero;
    Duration total = Duration.zero;
    for (var entry in fastingHistory) {
      var parts = entry.split(', ');
      var start = DateTime.parse(parts[0].split(': ')[1]);
      var end = DateTime.parse(parts[1].split(': ')[1]);
      total += end.difference(start);
    }
    return total ~/ fastingHistory.length;
  }

  @override
  Widget build(BuildContext context) {
    Duration longestFast = _calculateLongestFast();
    Duration averageFast = _calculateAverageFast();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Minimal Fasting Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (startTime == null)
              ElevatedButton(
                onPressed: startFasting,
                child: const Text('Start Fasting'),
              ),
            if (startTime != null && endTime == null)
              ElevatedButton(
                onPressed: stopFasting,
                child: const Text('Stop Fasting'),
              ),
            if (startTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Fasting started at: ${startTime.toString()}'),
              ),
            if (endTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Fasting ended at: ${endTime.toString()}'),
              ),
            const SizedBox(height: 20),
            const Text(
              'History:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: fastingHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(fastingHistory[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('Longest Fast: ${longestFast.inSeconds} seconds'),
            Text('Average Fast: ${averageFast.inSeconds} seconds'),
          ],
        ),
      ),
    );
  }
}
