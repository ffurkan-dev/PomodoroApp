import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const PomodoroTimer(),
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

enum PomodoroMode { focus, breakMode }

class _PomodoroTimerState extends State<PomodoroTimer> {
  PomodoroMode _mode = PomodoroMode.focus;
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _minutes = 25;
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  Task? _currentTask;
  Color _backgroundColor = Colors.white;

  void switchMode(PomodoroMode mode) {
    setState(() {
      _mode = mode;
      _timer?.cancel();
      _isRunning = false;
      if (_mode == PomodoroMode.focus) {
        _minutes = _focusMinutes;
      } else {
        _minutes = _breakMinutes;
      }
      _seconds = 0;
    });
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          if (_minutes > 0) {
            _minutes--;
            _seconds = 59;
          } else {
            _timer?.cancel();
            _isRunning = false;
          }
        }
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  void stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      if (_mode == PomodoroMode.focus) {
        _minutes = _focusMinutes;
      } else {
        _minutes = _breakMinutes;
      }
      _seconds = 0;
      _isRunning = false;
    });
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
                    // resetTimer();
                    startTimer(); 
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

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _backgroundColor;
        return AlertDialog(
          title: const Text('Pick a background color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                tempColor = color;
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Select'),
              onPressed: () {
                setState(() {
                  _backgroundColor = tempColor;
                });
                Navigator.of(context).pop();
              },
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: 'Change Background Color',
            onPressed: _pickColor,
          ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Focus'),
                    selected: _mode == PomodoroMode.focus,
                    onSelected: (selected) {
                      if (selected) switchMode(PomodoroMode.focus);
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Break'),
                    selected: _mode == PomodoroMode.breakMode,
                    onSelected: (selected) {
                      if (selected) switchMode(PomodoroMode.breakMode);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _mode == PomodoroMode.focus ? 'Focus Mode' : 'Break Mode',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_currentTask != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Current task: ${_currentTask!.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ),
              Text(
                '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRunning ? stopTimer : startTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: resetTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
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
