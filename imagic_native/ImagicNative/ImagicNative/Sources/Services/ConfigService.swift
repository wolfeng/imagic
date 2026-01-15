
import Foundation

class ConfigService {
    private let fileName = "magic_config.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }
    
    func loadConfig() -> MagicConfig {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return MagicConfig() // Return default empty config
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let config = try JSONDecoder().decode(MagicConfig.self, from: data)
            return config
        } catch {
            print("Failed to load config: \(error)")
            return MagicConfig()
        }
    }
    
    func saveConfig(_ config: MagicConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
