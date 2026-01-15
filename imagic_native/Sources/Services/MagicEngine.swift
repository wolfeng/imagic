
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
        if action == "exit" {
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
        var type: TriggerType?
        switch count {
        case 1: type = .tap1
        case 2: type = .tap2
        case 3: type = .tap3
        default: break
        }
        
        if let type = type {
            checkTriggers(type: type)
        }
    }
    
    func onLongPress() {
        checkTriggers(type: .longPress)
    }
    
    func onVideoFinished() {
        checkTriggers(type: .auto)
    }
    
    private func handleAudioLevel(_ db: Double) {
        if db > config.blowThreshold {
            checkTriggers(type: .blow)
        }
    }
    
    private func updateMonitoringState() {
        guard let stage = currentStage else { return }
        let needsBlow = stage.triggers.contains(where: { $0.type == .blow })
        
        if needsBlow {
            audioService.startMonitoring()
        } else {
            audioService.stopMonitoring()
        }
    }
    
    // MARK: - CRUD
    
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
