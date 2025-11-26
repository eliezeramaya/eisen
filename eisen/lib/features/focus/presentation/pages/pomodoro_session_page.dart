import 'dart:async';

import 'package:eisen/core/design_system/eisen_tokens.dart';
import 'package:eisen/features/focus/presentation/widgets/pomodoro_controls_row.dart';
import 'package:eisen/features/focus/presentation/widgets/pomodoro_session_summary.dart';
import 'package:eisen/features/focus/presentation/widgets/pomodoro_timer_card.dart';
import 'package:flutter/material.dart';

enum PomodoroSessionType { focus, breakSession, deepWork }

class PomodoroConfig {
  PomodoroConfig({
    required this.duration,
    required this.label,
    required this.type,
    this.taskTitle,
  });

  final Duration duration;
  final String label;
  final PomodoroSessionType type;
  final String? taskTitle;
}

class PomodoroSessionPage extends StatefulWidget {
  const PomodoroSessionPage({
    super.key,
    required this.initialDuration,
    this.presetLabel,
    this.taskTitle,
    this.sessionType = PomodoroSessionType.focus,
    this.autoStart = false,
  });

  final Duration initialDuration;
  final String? presetLabel;
  final String? taskTitle;
  final PomodoroSessionType sessionType;
  final bool autoStart;

  @override
  State<PomodoroSessionPage> createState() => _PomodoroSessionPageState();
}

class _PomodoroSessionPageState extends State<PomodoroSessionPage> {
  late Duration _total;
  late Duration _remaining;
  late PomodoroPhase _phase;
  late PomodoroSessionType _sessionType;
  int _cycle = 1;
  bool _isRunning = false;
  bool _hasStarted = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sessionType = widget.sessionType;
    _phase = _sessionType == PomodoroSessionType.breakSession
        ? PomodoroPhase.shortBreak
        : PomodoroPhase.focus;
    _total = widget.initialDuration;
    _remaining = widget.initialDuration;

    if (widget.autoStart) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPaused = !_isRunning && _hasStarted;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus session'),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EisenSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PomodoroTimerCard(
                remaining: _remaining,
                total: _total,
                phase: _phase,
                cycle: _cycle,
                presetLabel: widget.presetLabel,
                taskTitle: widget.taskTitle,
                isRunning: _isRunning,
              ),
              const SizedBox(height: EisenSpacing.lg),
              PomodoroControlsRow(
                isRunning: _isRunning,
                isPaused: isPaused,
                onStartOrResume: _startTimer,
                onPause: _pauseTimer,
                onReset: _resetTimer,
                onSkip: _phase == PomodoroPhase.shortBreak ||
                        _phase == PomodoroPhase.longBreak
                    ? _skipBreak
                    : null,
              ),
              const SizedBox(height: EisenSpacing.lg),
              PomodoroSessionSummary(
                taskTitle: widget.taskTitle,
                elapsed: _elapsed,
                cycle: _cycle,
                phase: _phase,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = true;
      _hasStarted = true;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _onTick();
    });
  }

  void _pauseTimer() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _hasStarted = false;
      _cycle = 1;
      _phase = _sessionType == PomodoroSessionType.breakSession
          ? PomodoroPhase.shortBreak
          : PomodoroPhase.focus;
      _total = widget.initialDuration;
      _remaining = widget.initialDuration;
      _elapsed = Duration.zero;
    });
  }

  void _skipBreak() {
    if (_phase == PomodoroPhase.shortBreak ||
        _phase == PomodoroPhase.longBreak) {
      _ticker?.cancel();
      setState(() {
        _phase = PomodoroPhase.focus;
        _total = widget.initialDuration;
        _remaining = widget.initialDuration;
        _isRunning = false;
      });
    }
  }

  void _onTick() {
    if (!_isRunning) return;
    if (_remaining.inSeconds <= 1) {
      setState(() {
        _elapsed += Duration(seconds: _remaining.inSeconds);
        _remaining = Duration.zero;
      });
      _completePhase();
    } else {
      setState(() {
        _remaining -= const Duration(seconds: 1);
        _elapsed += const Duration(seconds: 1);
      });
    }
  }

  void _completePhase() {
    _ticker?.cancel();

    if (_phase == PomodoroPhase.focus) {
      final isLongBreak = _cycle % 4 == 0;
      final nextDuration = isLongBreak
          ? const Duration(minutes: 15)
          : const Duration(minutes: 5);
      setState(() {
        _phase =
            isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
        _total = nextDuration;
        _remaining = nextDuration;
        _isRunning = true;
      });
      _startTimer();
    } else {
      setState(() {
        _cycle += 1;
        _phase = PomodoroPhase.focus;
        _total = widget.initialDuration;
        _remaining = widget.initialDuration;
        _isRunning = false;
      });
    }
  }
}
