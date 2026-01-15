
import Foundation
import AVFoundation

class AudioInputService {
    private var engine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    var onDecibelUpdate: ((Double) -> Void)?
    var isMonitoring = false
    
    init() {
        setupSession()
    }
    
    private func setupSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio Session Error: \(error)")
        }
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        engine = AVAudioEngine()
        guard let engine = engine else { return }
        
        inputNode = engine.inputNode
        let format = inputNode!.outputFormat(forBus: 0)
        
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processBuffer(buffer)
        }
        
        do {
            try engine.start()
            isMonitoring = true
        } catch {
            print("Audio Engine Start Error: \(error)")
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        inputNode?.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputNode = nil
        isMonitoring = false
    }
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }
        
        var sum: Float = 0
        for value in channelDataValueArray {
            sum += value * value
        }
        
        let rms = sqrt(sum / Float(buffer.frameLength))
        let db = 20 * log10(rms)
        
        DispatchQueue.main.async {
            self.onDecibelUpdate?(Double(db))
        }
    }
}
