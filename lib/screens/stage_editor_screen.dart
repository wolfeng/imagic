import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/magic_config.dart';

class StageEditorScreen extends StatefulWidget {
  final MagicStage? stage;
  final List<MagicStage> availableStages;
  final Function(MagicStage) onSave;

  const StageEditorScreen({
    super.key,
    this.stage,
    required this.availableStages,
    required this.onSave,
  });

  @override
  State<StageEditorScreen> createState() => _StageEditorScreenState();
}

class _StageEditorScreenState extends State<StageEditorScreen> {
  late TextEditingController _descController;
  late TextEditingController _sourceController;
  StageType _type = StageType.video;
  PlaybackMode _mode = PlaybackMode.oneShot;
  bool _showTime = false;

  // Minimal trigger editing for MVP: Single trigger configuration
  TriggerType _triggerType = TriggerType.auto;
  String _nextStageId = '1';

  @override
  void initState() {
    super.initState();
    final s = widget.stage;
    _descController = TextEditingController(text: s?.description ?? '');
    _sourceController = TextEditingController(text: s?.source ?? '');
    _type = s?.type ?? StageType.video;
    _mode = s?.mode ?? PlaybackMode.oneShot;
    _showTime = s?.showTime ?? false;

    if (s != null && s.triggers.isNotEmpty) {
      _triggerType = s.triggers.first.type;
      _nextStageId = s.triggers.first.nextStageId;
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: _type == StageType.video ? FileType.video : FileType.image,
    );

    if (result != null) {
      setState(() {
        _sourceController.text = result.files.single.path!;
      });
    }
  }

  void _save() {
    final newStage = MagicStage(
      id: widget.stage?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      source: _sourceController.text,
      mode: _mode,
      showTime: _showTime,
      triggers: [
        MagicTrigger(
          type: _triggerType,
          nextStageId: _nextStageId,
          action: _triggerType == TriggerType.auto && _nextStageId == 'exit'
              ? 'exit'
              : null,
        )
      ],
      description: _descController.text,
    );
    widget.onSave(newStage);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.stage == null ? "新建阶段 (New Stage)" : "编辑阶段 (Edit Stage)"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "备注名称 (Description)"),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<StageType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: "媒体类型 (Type)"),
            items: const [
              DropdownMenuItem(
                  value: StageType.video, child: Text("视频 (Video)")),
              DropdownMenuItem(
                  value: StageType.image, child: Text("图片 (Image)")),
            ],
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 10),
          // Toggle Time Overlay
          SwitchListTile(
            title: const Text("显示系统时间 (Show Clock)"),
            subtitle: const Text("在左上角显示当前时间 (逼真桌面)"),
            value: _showTime,
            onChanged: (v) => setState(() => _showTime = v),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sourceController,
                  decoration:
                      const InputDecoration(labelText: "文件路径 (Source Path)"),
                ),
              ),
              IconButton(
                  onPressed: _pickFile, icon: const Icon(Icons.folder_open)),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<PlaybackMode>(
            initialValue: _mode,
            decoration: const InputDecoration(labelText: "播放模式 (Mode)"),
            items: const [
              DropdownMenuItem(
                  value: PlaybackMode.oneShot, child: Text("单次播放")),
              DropdownMenuItem(value: PlaybackMode.loop, child: Text("循环播放")),
            ],
            onChanged: (v) => setState(() => _mode = v!),
          ),
          const Divider(height: 40),
          const Text("跳转条件 (Jump Condition)",
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<TriggerType>(
            initialValue: _triggerType,
            decoration: const InputDecoration(labelText: "触发类型 (Condition)"),
            items: const [
              DropdownMenuItem(
                  value: TriggerType.auto, child: Text("自动跳转 (Auto)")),
              DropdownMenuItem(
                  value: TriggerType.tap1, child: Text("单击 (Tap 1)")),
              DropdownMenuItem(
                  value: TriggerType.tap2, child: Text("双击 (Tap 2)")),
              DropdownMenuItem(
                  value: TriggerType.tap3, child: Text("三击 (Tap 3)")),
              DropdownMenuItem(
                  value: TriggerType.longPress, child: Text("长按 (Long Press)")),
              DropdownMenuItem(
                  value: TriggerType.blow, child: Text("吹气 (Blow)")),
            ],
            onChanged: (v) => setState(() => _triggerType = v!),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _availableTargetIds().contains(_nextStageId)
                ? _nextStageId
                : 'exit',
            decoration: const InputDecoration(labelText: "下一阶段 (Next Stage)"),
            items: _buildTargetItems(),
            onChanged: (v) => setState(() => _nextStageId = v!),
          ),
        ],
      ),
    );
  }

  List<String> _availableTargetIds() {
    return ['exit', ...widget.availableStages.map((s) => s.id)];
  }

  List<DropdownMenuItem<String>> _buildTargetItems() {
    final list = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'exit', child: Text("退出程序 (EXIT APP)")),
    ];

    for (var s in widget.availableStages) {
      if (s.id == widget.stage?.id) continue;
      String label = s.description.isEmpty ? "Stage ${s.id}" : s.description;
      list.add(DropdownMenuItem(value: s.id, child: Text(label)));
    }
    return list;
  }
}
