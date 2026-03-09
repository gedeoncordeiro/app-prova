import 'dart:async';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final int duration; // em segundos
  final VoidCallback onTimerComplete;

  const TimerWidget({
    super.key,
    required this.duration,
    required this.onTimerComplete,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _remainingSeconds;
  late Timer _timer;
  bool _isWarning = false;
  bool _isDanger = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _checkTimeStatus();
        } else {
          _timer.cancel();
          widget.onTimerComplete();
        }
      });
    });
  }

  void _checkTimeStatus() {
    final totalDuration = widget.duration;
    final remaining = _remainingSeconds;

    // Aviso quando restam 5 minutos
    if (remaining <= 300 && remaining > 60) {
      _isWarning = true;
      _isDanger = false;
    }
    // Perigo quando resta 1 minuto
    else if (remaining <= 60) {
      _isWarning = false;
      _isDanger = true;
    } else {
      _isWarning = false;
      _isDanger = false;
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor() {
    if (_isDanger) return Colors.red;
    if (_isWarning) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTimerColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getTimerColor().withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: _getTimerColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(_remainingSeconds),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(),
            ),
          ),
          if (_isDanger) ...[
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}