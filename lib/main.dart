import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Timer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PomodoroTimer(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  int _focusDuration = 25 * 60; // 25-minute focus duration
  int _breakDuration = 5 * 60; // 5-minute break duration
  int _timeLeft = 25 * 60; // remaining time in seconds
  bool _isRunning = false; // is timer running?
  bool _isFocusMode = true; // are we in focus mode?
  Timer? _timer;
  Task? _currentTask; // current task

  final AudioPlayer _rainPlayer = AudioPlayer();
  final AudioPlayer _firePlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer(); // for ding sound
  bool _isRainPlaying = false;
  bool _isFirePlaying = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  final List<String> _motivationalQuotes = [
    "You're doing great!",
    "Keep up the good work!",
    "Stay focused and keep going!",
    "One step at a time!",
    "Success is built one Pomodoro at a time!",
    "Breaks are part of progress!"
  ];

  @override
  void initState() {
    super.initState();
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  // Show notification with random motivational message
  void _showNotification() async {
    final random = Random();
    final message = _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];

    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      'Pomodoro Timer',
      _isFocusMode ? 'Break time! $message' : 'Focus time! $message',
      notificationDetails,
    );
  }

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _notificationPlayer.play(AssetSource('sounds/ding-36029.mp3'));
          _showNotification();
          _switchMode();
        }
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  // Pause the timer
  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  // Reset the timer
  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = _isFocusMode ? _focusDuration : _breakDuration;
      _isRunning = false;
    });
  }

  // Switch between focus and break mode
  void _switchMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      _timeLeft = _isFocusMode ? _focusDuration : _breakDuration;
    });
  }

  // Toggle rain sound
  Future<void> _toggleRainSound() async {
    if (_isRainPlaying) {
      await _rainPlayer.stop();
    } else {
      await _rainPlayer.setReleaseMode(ReleaseMode.loop);
      await _rainPlayer.play(AssetSource('sounds/rain-falling-30-seconds-329727.mp3'));
    }
    setState(() {
      _isRainPlaying = !_isRainPlaying;
    });
  }

  // Toggle fire sound
  Future<void> _toggleFireSound() async {
    if (_isFirePlaying) {
      await _firePlayer.stop();
    } else {
      await _firePlayer.setReleaseMode(ReleaseMode.loop);
      await _firePlayer.play(AssetSource('sounds/fire-sound-334130.mp3'));
    }
    setState(() {
      _isFirePlaying = !_isFirePlaying;
    });
  }

  // Convert seconds to mm:ss format
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Dispose resources
  @override
  void dispose() {
    _timer?.cancel();
    _rainPlayer.dispose();
    _firePlayer.dispose();
    _notificationPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsDialog,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _isFocusMode ? Colors.red.shade100 : Colors.green.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isFocusMode ? 'Focus Time' : 'Break Time',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _isFocusMode ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_currentTask != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    'Current task: ${_currentTask!.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _formatTime(_timeLeft),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: _isFocusMode ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _switchMode,
                icon: Icon(_isFocusMode ? Icons.coffee : Icons.work),
                label: Text(_isFocusMode ? 'Switch to Break' : 'Switch to Focus'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleRainSound,
                    icon: Icon(_isRainPlaying ? Icons.stop : Icons.audiotrack),
                    label: const Text("Rain"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _toggleFireSound,
                    icon: Icon(_isFirePlaying ? Icons.stop : Icons.local_fire_department),
                    label: const Text("Fire"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Open settings dialog
  void _openSettingsDialog() {
    final focusController = TextEditingController(text: (_focusDuration ~/ 60).toString());
    final breakController = TextEditingController(text: (_breakDuration ~/ 60).toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: focusController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Focus Time (minutes)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: breakController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Break Time (minutes)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int? newFocus = int.tryParse(focusController.text);
                final int? newBreak = int.tryParse(breakController.text);
                if (newFocus != null && newFocus > 0 && newBreak != null && newBreak > 0) {
                  setState(() {
                    _focusDuration = newFocus * 60;
                    _breakDuration = newBreak * 60;
                    _timeLeft = _isFocusMode ? _focusDuration : _breakDuration;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Add new task
  void _addTask(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Task name'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final taskName = _controller.text.trim();
                if (taskName.isNotEmpty) {
                  final newTask = Task(name: taskName);
                  setState(() {
                    _currentTask = newTask;
                    if (!_isFocusMode) _switchMode();
                    _resetTimer();
                    _startTimer();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Start Pomodoro'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class Task {
  String name;
  int pomodorosCompleted;
  Task({required this.name, this.pomodorosCompleted = 0});
}
