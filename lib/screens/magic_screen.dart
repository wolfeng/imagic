import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/magic_engine.dart';
import '../widgets/magic_media_view.dart';
import 'settings_screen.dart';

class MagicScreen extends StatefulWidget {
  const MagicScreen({super.key});

  @override
  State<MagicScreen> createState() => _MagicScreenState();
}

class _MagicScreenState extends State<MagicScreen> {
  void _showSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MagicSettingsScreen()),
    );
  }

  void _simulateTap1() => context.read<MagicEngine>().onTap(1);
  void _simulateTap2() => context.read<MagicEngine>().onTap(2);
  void _simulateTap3() => context.read<MagicEngine>().onTap(3);
  void _simulateLongPress() => context.read<MagicEngine>().onLongPress();
  void _simulateBlow() => context.read<MagicEngine>().onBlowTrigger();

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _showSettings,
        const SingleActivator(LogicalKeyboardKey.f1): _showSettings,
        // Debug Triggers
        const SingleActivator(LogicalKeyboardKey.space): _simulateTap1,
        const SingleActivator(LogicalKeyboardKey.digit2): _simulateTap2,
        const SingleActivator(LogicalKeyboardKey.digit3): _simulateTap3,
        const SingleActivator(LogicalKeyboardKey.keyL): _simulateLongPress,
        const SingleActivator(LogicalKeyboardKey.keyB): _simulateBlow,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.black, // Default background
          body: Stack(
            children: [
              // Media Layer
              const Positioned.fill(
                child: MagicMediaView(),
              ),

              // Gesture Layer (Unified)
              Positioned.fill(
                child: _MagicGestureDetector(
                  onTap: (count) => context.read<MagicEngine>().onTap(count),
                  onLongPress: () => context.read<MagicEngine>().onLongPress(),
                  onSwipeUp: _showSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MagicGestureDetector extends StatefulWidget {
  final Function(int) onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeUp;

  const _MagicGestureDetector({
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeUp,
  });

  @override
  State<_MagicGestureDetector> createState() => _MagicGestureDetectorState();
}

class _MagicGestureDetectorState extends State<_MagicGestureDetector> {
  int _tapCount = 0;
  int _lastTapTime = 0;

  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 400) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    _lastTapTime = now;

    // Greedy firing: Fire for every tap count immediately
    // 1st click -> fires onTap(1)
    // 2nd click -> fires onTap(2) (engine ignores 1 if stage expects 2)
    widget.onTap(_tapCount);

    // Reset count if we hit 3 to prevent infinite climbing
    if (_tapCount >= 3) {
      _tapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior:
          HitTestBehavior.translucent, // Allow clicks to pass visual layer
      onTap: _handleTap,
      onLongPress: widget.onLongPress,
      onVerticalDragUpdate: (details) {
        // Simple 1-finger swipe up detection for MVP
        if (details.delta.dy < -20) {
          widget.onSwipeUp();
        }
      },
      child: Container(color: Colors.transparent),
    );
  }
}
