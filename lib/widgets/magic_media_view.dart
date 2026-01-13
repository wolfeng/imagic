import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/magic_config.dart';
import '../services/magic_engine.dart';

class MagicMediaView extends StatefulWidget {
  const MagicMediaView({super.key});

  @override
  State<MagicMediaView> createState() => _MagicMediaViewState();
}

class _MagicMediaViewState extends State<MagicMediaView> {
  // Stack of active stage renderers.
  // Usually contains 1 item (current).
  // During transition, contains 2 items: [old, new].
  final List<MagicStage> _activeStages = [];

  // Track readiness of the stage at the top of the stack
  bool _isTransitioning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = context.watch<MagicEngine>();
    final currentStage = engine.currentStage;

    if (currentStage == null) {
      _activeStages.clear();
      return;
    }

    if (_activeStages.isEmpty) {
      // First load
      _activeStages.add(currentStage);
      _isTransitioning = true; // Wait for it to load
    } else if (_activeStages.last.id != currentStage.id) {
      // Stage changed. Push new stage to stack.
      // We keep the old one until new one is ready.
      // If we already have a pending stage that hasn't finished loading, replace it?
      // Simplified: If we are already transitioning, we might replace the top or just add.
      // For robustness: Just ensure the NEW target is at the end.

      // Remove any 'middle' stages if we were already transitioning and user switched again fast.
      // (Only keep the very first (visible) and the very new (target))
      if (_activeStages.length > 1) {
        _activeStages.removeRange(1, _activeStages.length);
      }

      _activeStages.add(currentStage);
      _isTransitioning = true;
    }
  }

  void _handleStageReady(String stageId) {
    if (!mounted) return;

    // If the stage that just became ready is the one at the end of our list (the target)
    if (_activeStages.isNotEmpty && _activeStages.last.id == stageId) {
      setState(() {
        // It's safe to remove all previous stages now, because the new one is painting valid bits.
        if (_activeStages.length > 1) {
          // Keep only the last one
          final newStage = _activeStages.last;
          _activeStages.clear();
          _activeStages.add(newStage);
        }
        _isTransitioning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeStages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Render stack.
    // The previous stage (index 0) is visible.
    // The new stage (index 1) is lazily loaded.
    // We used a Stack so they overlay.
    return Stack(
      children: _activeStages.map((stage) {
        // Important: We need a Key so the widget state persists across reorders/updates?
        // Actually we just map by ID.
        // We need to know if this specific stage instance is "visible" or just "preloading".
        // The last item is the "Target". The first item is "Current Visible".
        // If there is only 1 item, it is visible.
        // The internal renderer notifies us when it's ready.

        return Positioned.fill(
          key: ValueKey(stage.id), // Preserve state
          child: _StageRenderer(
            stage: stage,
            // If this is the target/new stage, we want to know when it's ready.
            onReady: () => _handleStageReady(stage.id),
          ),
        );
      }).toList(),
    );
  }
}

class _StageRenderer extends StatefulWidget {
  final MagicStage stage;
  final VoidCallback onReady;

  const _StageRenderer({
    required this.stage,
    required this.onReady,
  });

  @override
  State<_StageRenderer> createState() => _StageRendererState();
}

class _StageRendererState extends State<_StageRenderer> {
  VideoPlayerController? _videoController;
  Timer? _imageTimer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.stage.type == StageType.video) {
      _initializeVideo();
    } else if (widget.stage.type == StageType.image) {
      _initializeImage();
    }
  }

  void _initializeImage() {
    // Images are instant for our purposes, or close enough (Flutter caches).
    // But to be safe, we can defer one frame or use precacheImage.
    // For now, signal ready immediately in next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _signalReady();
      _checkImageAutoTrigger();
    });
  }

  void _checkImageAutoTrigger() {
    final hasAuto =
        widget.stage.triggers.any((t) => t.type == TriggerType.auto);
    if (hasAuto) {
      _imageTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          context.read<MagicEngine>().onVideoFinished();
        }
      });
    }
  }

  Future<void> _initializeVideo() async {
    final source = widget.stage.source;
    if (source.startsWith('assets/')) {
      _videoController = VideoPlayerController.asset(source);
    } else {
      _videoController = VideoPlayerController.file(File(source));
    }

    try {
      await _videoController!.initialize();

      if (widget.stage.mode == PlaybackMode.loop) {
        await _videoController!.setLooping(true);
      }

      // Auto play
      await _videoController!.play();

      if (widget.stage.mode == PlaybackMode.oneShot) {
        _videoController!.addListener(_checkVideoEnd);
      }

      _signalReady();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing video: $e");
      // Even on error, signal ready so we don't get stuck?
      // Or maybe stuck is better than black. Let's signal ready to fallback.
      _signalReady();
    }
  }

  void _signalReady() {
    if (mounted && !_isInitialized) {
      // Only signal once
      // We mark initialized locally for the build method
      setState(() => _isInitialized = true);
      widget.onReady();
    } else if (mounted) {
      widget.onReady(); // Just in case
    }
  }

  void _checkVideoEnd() {
    if (_videoController == null) return;
    if (_videoController!.value.isInitialized &&
        _videoController!.value.position >= _videoController!.value.duration) {
      Future.microtask(() {
        if (mounted) {
          context.read<MagicEngine>().onVideoFinished();
        }
      });
    }
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _videoController?.removeListener(_checkVideoEnd);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(); // Transparent
    }

    Widget content;
    if (widget.stage.type == StageType.image) {
      content = _buildImage();
    } else {
      content = _buildVideo();
    }

    // Check for showTime flag
    if (widget.stage.showTime) {
      return Stack(
        fit: StackFit.expand,
        children: [
          content,
          const Positioned(
            top: 20,
            left: 20,
            child: _ClockOverlay(),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildImage() {
    final source = widget.stage.source;
    ImageProvider provider;
    if (source.startsWith('assets/')) {
      provider = AssetImage(source);
    } else {
      provider = FileImage(File(source));
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );
  }

  Widget _buildVideo() {
    if (_videoController == null) {
      return const SizedBox();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }
}

class _ClockOverlay extends StatefulWidget {
  const _ClockOverlay();
  @override
  State<_ClockOverlay> createState() => _ClockOverlayState();
}

class _ClockOverlayState extends State<_ClockOverlay> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format: HH:mm (24h)
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final timeStr = "$hour:$minute";

    return Material(
      color: Colors.transparent,
      child: Text(
        timeStr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 2,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
