import AVFoundation
import Combine

class AudioInputManager: NSObject, ObservableObject {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    
    // Threshold for detecting a "blow". This needs calibration.
    // Blows are usually consistently loud low-frequency noise.
    // Simple decibel check for MVP.
    private let blowThreshold: Float = -10.0 // dB (0 is max)
    
    var onBlowDetected: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func startMonitoring() {
        requestPermission { [weak self] granted in
            guard granted else { return }
            self?.startRecording()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
    }
    
    private func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    print("Microphone permission denied")
                }
                completion(granted)
            }
        }
    }
    
    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
            
            let url = URL(fileURLWithPath: "/dev/null")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            
            startTimer()
            print("Audio monitoring started")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkAudioLevel()
        }
    }
    
    private func checkAudioLevel() {
        guard let recorder = recorder else { return }
        recorder.updateMeters()
        
        let power = recorder.averagePower(forChannel: 0)
        // print("Audio Level: \(power)") // Debug
        
        if power > blowThreshold {
            print("Blow detected with power: \(power)")
            onBlowDetected?()
            // Optional: Debounce or stop monitoring to prevent multiple triggers
        }
    }
}
