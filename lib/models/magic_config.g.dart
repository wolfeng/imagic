// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'magic_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MagicConfig _$MagicConfigFromJson(Map<String, dynamic> json) => MagicConfig(
      stages: (json['stages'] as List<dynamic>)
          .map((e) => MagicStage.fromJson(e as Map<String, dynamic>))
          .toList(),
      blowThreshold: (json['blowThreshold'] as num?)?.toDouble() ?? -10.0,
    );

Map<String, dynamic> _$MagicConfigToJson(MagicConfig instance) =>
    <String, dynamic>{
      'stages': instance.stages.map((e) => e.toJson()).toList(),
      'blowThreshold': instance.blowThreshold,
    };

MagicStage _$MagicStageFromJson(Map<String, dynamic> json) => MagicStage(
      id: json['id'] as String,
      type: $enumDecode(_$StageTypeEnumMap, json['type']),
      source: json['source'] as String,
      mode: $enumDecode(_$PlaybackModeEnumMap, json['mode']),
      triggers: (json['triggers'] as List<dynamic>)
          .map((e) => MagicTrigger.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String? ?? '',
      showTime: json['showTime'] as bool? ?? false,
    );

Map<String, dynamic> _$MagicStageToJson(MagicStage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$StageTypeEnumMap[instance.type]!,
      'source': instance.source,
      'mode': _$PlaybackModeEnumMap[instance.mode]!,
      'triggers': instance.triggers,
      'description': instance.description,
      'showTime': instance.showTime,
    };

const _$StageTypeEnumMap = {
  StageType.image: 'image',
  StageType.video: 'video',
};

const _$PlaybackModeEnumMap = {
  PlaybackMode.oneShot: 'one_shot',
  PlaybackMode.loop: 'loop',
};

MagicTrigger _$MagicTriggerFromJson(Map<String, dynamic> json) => MagicTrigger(
      type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
      nextStageId: json['nextStageId'] as String,
      action: json['action'] as String?,
    );

Map<String, dynamic> _$MagicTriggerToJson(MagicTrigger instance) =>
    <String, dynamic>{
      'type': _$TriggerTypeEnumMap[instance.type]!,
      'nextStageId': instance.nextStageId,
      'action': instance.action,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.auto: 'auto',
  TriggerType.tap1: 'tap_1',
  TriggerType.tap2: 'tap_2',
  TriggerType.tap3: 'tap_3',
  TriggerType.longPress: 'long_press',
  TriggerType.blow: 'blow',
  TriggerType.none: 'none',
};
