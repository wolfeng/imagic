
import Foundation
import SwiftUI
import Combine

class MagicEngine: ObservableObject {
    @Published var config: MagicConfig
    @Published var currentStage: MagicStage?
    
    // Services
    private let configService = ConfigService()
    private let audioService = AudioInputService()
    
    init() {
        let loadedConfig = configService.loadConfig()
        self.config = loadedConfig
        
        // Setup Audio Callback
        audioService.onDecibelUpdate = { [weak self] db in
            self?.handleAudioLevel(db)
        }
        
        // Initialize Stage
        if let first = config.stages.first {
            transitionToStage(stageId: first.id)
        }
    }
    
    // MARK: - Transitions
    
    func transitionToStage(stageId: String, action: String? = nil) {
        if stageId == "exit" {
            // In SwiftUI app lifecycle, exit(0) is harsh but effective for "magic" apps
            exit(0) 
        }
        
        guard let stage = config.stages.first(where: { $0.id == stageId }) else { return }
        
        DispatchQueue.main.async {
            self.currentStage = stage
            self.updateMonitoringState()
        }
    }
    
    private func checkTriggers(type: TriggerType) {
        guard let stage = currentStage else { return }
        
        if let trigger = stage.triggers.first(where: { $0.type == type }) {
            print("Trigger Activated: \(type) -> Next: \(trigger.nextStageId)")
            transitionToStage(stageId: trigger.nextStageId, action: trigger.action)
        }
    }
    
    // MARK: - Inputs
    
    func onTap(count: Int) {
        if count == 1 { checkTriggers(type: .tap1) }
        else if count == 2 { checkTriggers(type: .tap2) }
        else if count == 3 { checkTriggers(type: .tap3) }
    }
    
    func onLongPress() {
        checkTriggers(type: .longPress)
    }
    
    func onCircle() {
        checkTriggers(type: .circle)
    }
    
    func onShake() {
        checkTriggers(type: .shake)
    }
    
    func onProximity() {
        checkTriggers(type: .proximity)
    }
    
    func onVideoFinished() {
        checkTriggers(type: .auto)
    }
    
    private func handleAudioLevel(_ db: Double) {
        // print("Audio Level: \(db)") // Debug uncomment if needed
        if db > config.blowThreshold {
            print("Blow Detected! Level: \(db) > \(config.blowThreshold)")
            checkTriggers(type: .blow)
        }
    }
    
    private func updateMonitoringState() {
        guard let stage = currentStage else { return }
        let needsBlow = stage.triggers.contains(where: { $0.type == .blow })
        let needsProximity = stage.triggers.contains(where: { $0.type == .proximity })
        
        if needsBlow {
            audioService.startMonitoring()
        } else {
            audioService.stopMonitoring()
        }
        
        // Proximity Monitoring
        let device = UIDevice.current
        if needsProximity {
            device.isProximityMonitoringEnabled = true
            NotificationCenter.default.addObserver(self, selector: #selector(proximityChanged), name: UIDevice.proximityStateDidChangeNotification, object: device)
        } else {
            device.isProximityMonitoringEnabled = false
            NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: device)
        }
    }
    
    @objc func proximityChanged(_ notification: Notification) {
        if UIDevice.current.proximityState {
            onProximity()
        }
    }
    
    // MARK: - CRUD
    
    func removeStage(at offsets: IndexSet) {
        config.stages.remove(atOffsets: offsets)
        configService.saveConfig(config)
    }

    func reload() {
        if let first = config.stages.first {
            transitionToStage(stageId: first.id)
        } else {
            DispatchQueue.main.async {
                self.currentStage = nil
            }
        }
    }
    
    func saveStage(_ stage: MagicStage) {
        if let index = config.stages.firstIndex(where: { $0.id == stage.id }) {
            config.stages[index] = stage
        } else {
            config.stages.append(stage)
        }
        configService.saveConfig(config)
        
        // Update current if needed
        if currentStage?.id == stage.id {
            currentStage = stage
            updateMonitoringState()
        }
    }
}
