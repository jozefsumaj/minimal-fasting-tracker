import 'package:flutter/material.dart';

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

  void startFasting() {
    setState(() {
      startTime = DateTime.now();
      endTime = null;
    });
  }

  void stopFasting() {
    setState(() {
      endTime = DateTime.now();
      if (startTime != null) {
        fastingHistory.add('Started: ${startTime.toString()}, Ended: ${endTime.toString()}');
        startTime = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Fasting started at: ${startTime.toString()}'),
            if (endTime != null)
              Text('Fasting ended at: ${endTime.toString()}'),
            const SizedBox(height: 20),
            const Text('History:'),
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
          ],
        ),
      ),
    );
  }
}
