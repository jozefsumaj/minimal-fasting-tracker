import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadFastingHistory();
    _initNotifications();
  }

  void _initNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'fasting_tracker_nofitication', 'Fasting Start/End Notifications',
        importance: Importance.max, priority: Priority.high, showWhen: false);
    const platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
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
      _elapsedTime = Duration.zero;
    });
    _startTimer();
    _showNotification('Fasting started', 'Your fasting period has begun');
  }

  void stopFasting() {
    setState(() {
      endTime = DateTime.now();
      _timer?.cancel();
      if (startTime != null) {
        fastingHistory.add(
            'Started: ${startTime.toString()}, Ended: ${endTime.toString()}');
        startTime = null;
        _saveFastingHistory();
      }
    });
    _showNotification('Fasting ended', 'Your fasting period has ended');
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(startTime!);
      });
    });
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
            // circle button
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 40.0,
                    backgroundWidth: 40.0,
                    percent: _elapsedTime.inSeconds % 60 / 60,
                    center: ElevatedButton(
                      onPressed: () => startTime == null ? startFasting() : stopFasting(),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(40),
                        elevation: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(startTime == null ? Icons.play_arrow : Icons.stop, size: 30),
                          Text(
                            startTime == null ? 'Start fasting' : 'Stop fasting',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    progressColor: Colors.greenAccent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Elapsed Time: ${_formatDuration(_elapsedTime)}'),
                ),
              ],
            ),

            const Text(
              'History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            
            // history heatmap/grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 10,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0),
                itemCount: fastingHistory.length,
                itemBuilder: (context, index) {
                  var entry = fastingHistory[index];
                  var parts = entry.split(', ');
                  var start = DateTime.parse(parts[0].split(': ')[1]);
                  var end = DateTime.parse(parts[1].split(': ')[1]);
                  var duration = end.difference(start);

                  return Container(
                    decoration: BoxDecoration(
                      color: _getColorForDuration(duration),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Center(
                      child: Text(
                        '${duration.inMinutes}m',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Color _getColorForDuration(Duration duration) {
    int seconds = duration.inSeconds;
    int maxSeconds = 60; // You can adjust this based on your needs
    int intensity = (255 * (seconds / maxSeconds)).clamp(0, 255).toInt();
    return Color.fromARGB(
        255, intensity, 255 - intensity, 0); // Green to Red scale
  }
}
