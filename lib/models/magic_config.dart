import 'package:json_annotation/json_annotation.dart';

part 'magic_config.g.dart';

@JsonSerializable(explicitToJson: true)
class MagicConfig {
  final List<MagicStage> stages;
  final double blowThreshold; // Decibels, e.g. -10.0

  MagicConfig({
    required this.stages,
    this.blowThreshold = -10.0,
  });

  factory MagicConfig.fromJson(Map<String, dynamic> json) =>
      _$MagicConfigFromJson(json);
  Map<String, dynamic> toJson() => _$MagicConfigToJson(this);
}

enum StageType {
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
}

enum PlaybackMode {
  @JsonValue('one_shot')
  oneShot,
  @JsonValue('loop')
  loop,
}

enum TriggerType {
  @JsonValue('auto')
  auto, // Finishes and goes to next
  @JsonValue('tap_1')
  tap1, // Single tap
  @JsonValue('tap_2')
  tap2, // Double tap
  @JsonValue('tap_3')
  tap3, // Triple tap
  @JsonValue('long_press')
  longPress,
  @JsonValue('blow')
  blow,
  @JsonValue('none')
  none, // Waits for explicit jump or stays loop
}

@JsonSerializable()
class MagicStage {
  final String id;
  final StageType type;
  final String source; // filename in assets or local path
  final PlaybackMode mode;
  final List<MagicTrigger> triggers;

  // Helper for UI editor
  final String description;
  final bool showTime; // Show system time overlay

  MagicStage({
    required this.id,
    required this.type,
    required this.source,
    required this.mode,
    required this.triggers,
    this.description = '',
    this.showTime = false,
  });

  factory MagicStage.fromJson(Map<String, dynamic> json) =>
      _$MagicStageFromJson(json);
  Map<String, dynamic> toJson() => _$MagicStageToJson(this);
}

@JsonSerializable()
class MagicTrigger {
  final TriggerType type;
  final String nextStageId;
  final String? action; // 'exit', 'restart'

  MagicTrigger({
    required this.type,
    required this.nextStageId,
    this.action,
  });

  factory MagicTrigger.fromJson(Map<String, dynamic> json) =>
      _$MagicTriggerFromJson(json);
  Map<String, dynamic> toJson() => _$MagicTriggerToJson(this);
}
