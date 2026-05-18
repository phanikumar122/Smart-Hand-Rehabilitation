import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/glove_data_provider.dart';
import '../utils/theme.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({Key? key}) : super(key: key);

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSession(GloveDataProvider provider) {
    if (provider.isSessionActive) {
      provider.stopSession();
      _timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session Saved!')));
      setState(() => _secondsElapsed = 0);
    } else {
      provider.startSession();
      _secondsElapsed = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rehabilitation Session')),
      body: Consumer<GloveDataProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_secondsElapsed),
                  style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _toggleSession(provider),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.isSessionActive ? AppTheme.errorColor : AppTheme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: (provider.isSessionActive ? AppTheme.errorColor : AppTheme.primaryColor).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        provider.isSessionActive ? 'STOP' : 'START',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.backgroundColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (provider.isSessionActive)
                  const Text('Recording data...', style: TextStyle(color: Colors.grey, fontSize: 18))
                else
                  const Text('Ready to begin new session', style: TextStyle(color: Colors.grey, fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );
  }
}
