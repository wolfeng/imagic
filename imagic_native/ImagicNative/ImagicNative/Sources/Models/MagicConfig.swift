import Foundation

// MARK: - Enums

enum StageType: String, Codable {
    case image
    case video
}

enum PlaybackMode: String, Codable {
    case oneShot = "one_shot"
    case loop
}

enum TriggerType: String, Codable, CaseIterable {
    case auto
    case tap1 = "tap_1"
    case tap2 = "tap_2"
    case tap3 = "tap_3"
    case longPress = "long_press"
    case blow
    case circle
    case shake // New: Shake device
    case proximity // New: Cover sensor (Hand wave/Face down)
    case none
}

enum AppLanguage: String, Codable, CaseIterable {
    case english = "English"
    case chinese = "中文"
    case japanese = "日本語"
    case french = "Français"
    case german = "Deutsch"
    case spanish = "Español"
}

// MARK: - Models

struct MagicConfig: Codable {
    var stages: [MagicStage]
    var blowThreshold: Double // e.g. -10.0
    var language: AppLanguage
    
    init(stages: [MagicStage] = [], blowThreshold: Double = -10.0, language: AppLanguage = .english) {
        self.stages = stages
        self.blowThreshold = blowThreshold
        self.language = language
    }
}

struct MagicStage: Codable, Identifiable {
    var id: String
    var type: StageType
    var source: String // filename or path
    var mode: PlaybackMode
    var triggers: [MagicTrigger]
    var description: String
    var showTime: Bool
    
    init(id: String = UUID().uuidString,
         type: StageType = .video,
         source: String = "",
         mode: PlaybackMode = .oneShot,
         triggers: [MagicTrigger] = [],
         description: String = "",
         showTime: Bool = false) {
        self.id = id
        self.type = type
        self.source = source
        self.mode = mode
        self.triggers = triggers
        self.description = description
        self.showTime = showTime
    }
}

struct MagicTrigger: Codable, Identifiable {
    var id: String = UUID().uuidString
    var type: TriggerType
    var nextStageId: String
    var action: String? // "exit", etc.
    
    enum CodingKeys: String, CodingKey {
        case type, nextStageId, action
    }
    
    init(type: TriggerType, nextStageId: String, action: String? = nil) {
        self.type = type
        self.nextStageId = nextStageId
        self.action = action
    }
}
