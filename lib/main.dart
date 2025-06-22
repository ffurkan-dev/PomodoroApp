import 'package:flutter/material.dart';
import 'dart:async';

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
  int _focusDuration = 25 * 60; // 25 minutes in seconds
  int _breakDuration = 5 * 60; // 5 minutes in seconds
  
  int _timeLeft = 25 * 60;
  bool _isRunning = false;
  bool _isFocusMode = true;
  Timer? _timer;
  Task? _currentTask;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _switchMode();
        }
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = _isFocusMode ? _focusDuration : _breakDuration;
      _isRunning = false;
    });
  }

  void _switchMode() {
    setState(() {
      _isFocusMode = !_isFocusMode;
      _timeLeft = _isFocusMode ? _focusDuration : _breakDuration;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

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
                decoration: const InputDecoration(
                  labelText: 'Focus Time (minutes)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: breakController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Break Time (minutes)',
                ),
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

  @override
  void dispose() {
    _timer?.cancel();
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
}

class Task {
  String name;
  int pomodorosCompleted; // for later 
  Task({required this.name, this.pomodorosCompleted = 0});
}
