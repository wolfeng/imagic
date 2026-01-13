import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/magic_config.dart';
import '../services/magic_engine.dart';
import 'stage_editor_screen.dart';

class MagicSettingsScreen extends StatefulWidget {
  const MagicSettingsScreen({super.key});

  @override
  State<MagicSettingsScreen> createState() => _MagicSettingsScreenState();
}

class _MagicSettingsScreenState extends State<MagicSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("魔术流程配置"),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Reload/Restart the flow
              context.read<MagicEngine>().initialize();
              Navigator.pop(context);
            },
          )
        ],
      ),
      backgroundColor: Colors.grey[850], // Dark theme
      body: Consumer<MagicEngine>(
        builder: (context, engine, _) {
          final config = engine.config;
          if (config == null) return const Center(child: Text("暂无配置，请点击右下角添加"));

          return ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              // Reorder logic not implemented in Engine yet for simpler list,
              // but UI requires this callback.
              // engine.reorderStages(oldIndex, newIndex);
            },
            children: [
              for (int i = 0; i < config.stages.length; i++)
                Dismissible(
                  key: ValueKey(config.stages[i].id),
                  background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    engine.removeStage(config.stages[i].id);
                  },
                  child: _buildStageItem(context, config.stages[i], i, engine),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          final engine = context.read<MagicEngine>();
          if (engine.config == null) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StageEditorScreen(
                availableStages: engine.config!.stages,
                onSave: (newStage) {
                  engine.addStage(newStage);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageItem(
      BuildContext context, MagicStage stage, int index, MagicEngine engine) {
    return Card(
      // key: ValueKey(stage.id), // Key is handled by Dismissible parent
      color: Colors.grey[800],
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Icon(
          stage.type == StageType.video ? Icons.videocam : Icons.image,
          color: Colors.tealAccent,
        ),
        title: Text(
          stage.description.isEmpty ? "阶段 ${index + 1}" : stage.description,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          _getStageSubtitle(stage),
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StageEditorScreen(
                stage: stage,
                availableStages: engine.config!.stages,
                onSave: (updatedStage) {
                  engine.updateStage(updatedStage);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _getStageSubtitle(MagicStage stage) {
    String modeStr = stage.mode == PlaybackMode.loop ? "循环" : "单次";
    String triggerStr = stage.triggers.map((t) {
      switch (t.type) {
        case TriggerType.tap1:
          return "单击";
        case TriggerType.tap2:
          return "双击";
        case TriggerType.tap3:
          return "三击";
        case TriggerType.longPress:
          return "长按";
        case TriggerType.blow:
          return "吹气";
        case TriggerType.auto:
          return "自动";
        default:
          return t.type.name;
      }
    }).join(', ');
    return "$modeStr • 触发: $triggerStr";
  }
}
