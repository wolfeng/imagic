import 'dart:async';
import 'package:record/record.dart';

class AudioInputService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _pollingTimer;
  final Function(double) onDecibelUpdate;
  bool _isRecording = false;

  AudioInputService({required this.onDecibelUpdate});

  Future<void> startMonitoring() async {
    if (_isRecording) return;

    if (await _recorder.hasPermission()) {
      // Start recording to stream
      // We use a dummy file or stream. 
      // 'record' package v5 supports starting with stream output (no file) by passing StreamSink
      // But standard implementation for amplitude often requires recording to a file on some platforms, 
      // or just starting generic record and polling getAmplitude.
      
      // We'll record to a null path/stream just to activate the mic
      try {
        final stream = await _recorder.startStream(const RecordConfig(
          encoder: AudioEncoder.aacLc, // efficient
        ));
        
        // We actually just need the amplitude, so we don't care about the stream data much.
        // We'll drain it to prevent buffer fill if needed, though startStream usually handles it.
        stream.drain(); 

        _isRecording = true;
        _startPolling();
        print("Audio Monitoring Started");
      } catch (e) {
        print("Error starting audio recording: $e");
      }
    } else {
      print("Microphone permission denied");
    }
  }

  Future<void> stopMonitoring() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
      print("Audio Monitoring Stopped");
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording) return;
      
      try {
        final amplitude = await _recorder.getAmplitude();
        // amplitude.current is in dBFS (usually -160 to 0)
        onDecibelUpdate(amplitude.current);
      } catch (e) {
        print("Error getting amplitude: $e");
      }
    });
  }
}
