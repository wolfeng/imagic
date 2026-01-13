import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/magic_config.dart';

class MagicConfigService {
  static const String _fileName = 'magic_config.json';

  /// Loads config from local storage, falling back to default asset if not found.
  Future<MagicConfig> loadConfig() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonMap = jsonDecode(jsonString);
        return MagicConfig.fromJson(jsonMap);
      } else {
        return _createDefaultConfig();
      }
    } catch (e) {
      print("Error loading config: $e");
      return _createDefaultConfig();
    }
  }

  /// Saves the current config to local storage.
  Future<void> saveConfig(MagicConfig config) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      final jsonString = jsonEncode(config.toJson());
      await file.writeAsString(jsonString);
      print("Config saved to ${file.path}");
    } catch (e) {
      print("Error saving config: $e");
    }
  }

  /// Returns a default configuration for first launch (The "Classic" Trick).
  MagicConfig _createDefaultConfig() {
    return MagicConfig(
      blowThreshold: -10.0,
      stages: [], // Empty by default as requested
    );
  }
}
