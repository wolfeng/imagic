import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/magic_config.dart';
import '../services/magic_config_service.dart';
import '../services/audio_input_service.dart';

class MagicEngine extends ChangeNotifier {
  final MagicConfigService _configService = MagicConfigService();
  late AudioInputService _audioService;

  MagicConfig? _config;
  MagicStage? _currentStage;

  MagicStage? get currentStage => _currentStage;
  MagicConfig? get config => _config;
  bool get isLoaded => _config != null;

  // Audio Monitoring State
  bool _isMonitoringBlow = false;

  MagicEngine() {
    _audioService = AudioInputService(onDecibelUpdate: _handleAudioLevel);
  }

  Future<void> initialize() async {
    _config = await _configService.loadConfig();
    if (_config!.stages.isNotEmpty) {
      _currentStage = _config!.stages.first;
      _handleStageEntry();
    }
    notifyListeners();
  }

  // --- Trigger Handlers ---

  void onTap(int count) {
    if (_currentStage == null) return;

    // Find matching triggers
    // We prioritize specific count match
    TriggerType? type;
    if (count == 1) {
      type = TriggerType.tap1;
    } else if (count == 2)
      type = TriggerType.tap2;
    else if (count == 3) type = TriggerType.tap3;

    if (type != null) {
      _checkTriggers(type);
    }
  }

  void onLongPress() {
    _checkTriggers(TriggerType.longPress);
  }

  void onBlowTrigger() {
    _checkTriggers(TriggerType.blow);
  }

  void _handleAudioLevel(double decibels) {
    if (_config == null) return;

    // print("dB: $decibels"); // Debug
    if (decibels > _config!.blowThreshold) {
      // Debounce slightly if needed, but for now direct trigger
      _checkTriggers(TriggerType.blow);
    }
  }

  void onVideoFinished() {
    _checkTriggers(TriggerType.auto);
  }

  // --- Private Logic ---

  void _checkTriggers(TriggerType type) {
    if (_currentStage == null) return;

    try {
      final trigger = _currentStage!.triggers.firstWhere(
        (t) => t.type == type,
      );

      // Found a matching trigger
      print("Trigger Activated: $type -> Next: ${trigger.nextStageId}");
      _transitionToStage(trigger.nextStageId, trigger.action);
    } catch (_) {
      // No trigger found for this type, ignore
    }
  }

  void _transitionToStage(String stageId, String? action) {
    if (_config == null) return;

    if (action == 'exit') {
      exit(0); // Native exit as requested
      // Note: requires 'dart:io' import
    }

    try {
      final nextStage = _config!.stages.firstWhere((s) => s.id == stageId);
      _currentStage = nextStage;
      notifyListeners();
      _handleStageEntry();
    } catch (e) {
      print("Error: Target stage $stageId not found!");
    }
  }

  // --- Config Management ---

  void updateStage(MagicStage stage) {
    if (_config == null) return;
    final index = _config!.stages.indexWhere((s) => s.id == stage.id);
    if (index != -1) {
      _config!.stages[index] = stage;
      notifyListeners();
      _saveConfig();
    }
  }

  void addStage(MagicStage stage) {
    if (_config == null) return;
    final wasEmpty = _config!.stages.isEmpty;
    _config!.stages.add(stage);

    if (wasEmpty || _currentStage == null) {
      _currentStage = stage;
      _handleStageEntry();
    }

    notifyListeners();
    _saveConfig();
  }

  void removeStage(String stageId) {
    if (_config == null) return;
    _config!.stages.removeWhere((s) => s.id == stageId);
    notifyListeners();
    _saveConfig();
  }

  Future<void> _saveConfig() async {
    if (_config != null) {
      await _configService.saveConfig(_config!);
    }
  }

  void _handleStageEntry() {
    if (_currentStage == null) return;

    // Logic when entering a new stage
    // e.g. Start audio monitoring if this stage requires blow detection
    final needsBlow =
        _currentStage!.triggers.any((t) => t.type == TriggerType.blow);

    if (needsBlow && !_isMonitoringBlow) {
      print("Enabling Mic Monitoring");
      _isMonitoringBlow = true;
      _audioService.startMonitoring();
    } else if (!needsBlow && _isMonitoringBlow) {
      print("Disabling Mic Monitoring");
      _isMonitoringBlow = false;
      _audioService.stopMonitoring();
    }
  }
}
