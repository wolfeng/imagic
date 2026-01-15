import SwiftUI
import PhotosUI
import AVKit

struct SettingsView: View {
    @ObservedObject var engine: MagicEngine
    @Environment(\.presentationMode) var presentationMode
    
    // Helper for cleaner code
    func loc(_ key: String) -> String {
        Localization.get(key, for: engine.config.language)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text(loc("Stages"))) {
                    ForEach(engine.config.stages) { stage in
                        NavigationLink(destination: StageEditor(stage: stage, engine: engine)) {
                            HStack {
                                Text(stage.description.isEmpty ? stage.id : stage.description)
                                Spacer()
                                Text(loc(stage.type.rawValue.capitalized)).foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        engine.removeStage(at: indexSet)
                    }
                }
                
                Section {
                    Button(loc("Add New Stage")) {
                        let newStage = MagicStage(description: "New Stage")
                        engine.saveStage(newStage)
                    }
                }
                
                Section(header: Text(loc("Global Config"))) {
                    HStack {
                        Text(loc("Blow Threshold (dB)"))
                        Spacer()
                        // Sensitivity Slider: 0 to 100
                        // Mapped to Threshold: 0 dB to -30 dB (More precise range)
                        // Formula: Threshold = -0.3 * Sensitivity
                        Slider(
                            value: Binding(
                                get: {
                                    let val = engine.config.blowThreshold / -0.3
                                    return min(max(val, 0), 100)
                                },
                                set: { engine.config.blowThreshold = $0 * -0.3 }
                            ),
                            in: 0...100,
                            step: 1
                        )
                        .frame(width: 150)
                        
                        Text("\(Int(min(max(engine.config.blowThreshold / -0.3, 0), 100)))")
                            .monospacedDigit()
                    }
                    
                    Picker(loc("Language"), selection: $engine.config.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                }
            }
            .navigationTitle(loc("Settings"))
            .navigationBarItems(trailing: Button(loc("Done")) {
                engine.reload()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct StageEditor: View {
    @State var stage: MagicStage
    var engine: MagicEngine
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    func loc(_ key: String) -> String {
        Localization.get(key, for: engine.config.language)
    }
    
    var body: some View {
        Form {
            Section(header: Text(loc("Info"))) {
                TextField(loc("Description"), text: $stage.description)
                Picker(loc("Type"), selection: $stage.type) {
                    Text(loc("Video")).tag(StageType.video)
                    Text(loc("Image")).tag(StageType.image)
                }
                
                VStack(alignment: .leading) {
                    Text(loc("Source Media")).font(.caption).foregroundColor(.secondary)
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: stage.type == .video ? .videos : .images,
                        photoLibrary: .shared()
                    ) {
                        MediaThumbnailView(source: stage.source, type: stage.type)
                            .id(stage.source) // Force recreate when source changes
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let newItem = newItem {
                                await loadMedia(item: newItem)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text(loc("Playback"))) {
                Picker(loc("Mode"), selection: $stage.mode) {
                    Text(loc("One Shot")).tag(PlaybackMode.oneShot)
                    Text(loc("Loop")).tag(PlaybackMode.loop)
                }
                Toggle(loc("Show Clock"), isOn: $stage.showTime)
            }
            
            Section(header: Text(loc("Triggers"))) {
                ForEach($stage.triggers) { $trigger in
                    TriggerRow(trigger: $trigger, stages: engine.config.stages, language: engine.config.language)
                }
                .onDelete { indexSet in
                    stage.triggers.remove(atOffsets: indexSet)
                }
                
                Button(loc("Add Trigger")) {
                    stage.triggers.append(MagicTrigger(type: .tap1, nextStageId: "exit"))
                }
            }
        }
        .navigationTitle(loc("Edit Stage")) // Dynamic title is tricky with State but okay
        .navigationBarItems(trailing: Button(loc("Save")) {
            engine.saveStage(stage)
            presentationMode.wrappedValue.dismiss()
        })
    }
    
    // Helper to load and save media
    private func loadMedia(item: PhotosPickerItem) async {
        do {
            // Determine type
            if stage.type == .video {
                if let movie = try await item.loadTransferable(type: MovieFile.self) {
                    saveFile(url: movie.url)
                }
            } else {
                if let data = try await item.loadTransferable(type: Data.self) {
                    saveImageData(data)
                }
            }
        } catch {
            print("Failed to load media: \(error)")
        }
    }
    
    private func saveFile(url: URL) {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = url.lastPathComponent
        let destURL = docURL.appendingPathComponent(fileName)
        
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: url, to: destURL)
            DispatchQueue.main.async {
                self.stage.source = destURL.path
            }
        } catch {
            print("File copy error: \(error)")
        }
    }
    
    private func saveImageData(_ data: Data) {
        let fileManager = FileManager.default
        let docURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "img_\(UUID().uuidString).jpg"
        let destURL = docURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: destURL)
            DispatchQueue.main.async {
                self.stage.source = destURL.path
            }
        } catch {
            print("Image save error: \(error)")
        }
    }
}

// Transferable wrapper for Video
import CoreTransferable

struct MovieFile: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("import_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

struct TriggerRow: View {
    @Binding var trigger: MagicTrigger
    var stages: [MagicStage]
    var language: AppLanguage
    
    func loc(_ key: String) -> String {
        Localization.get(key, for: language)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Picker(loc("Action"), selection: $trigger.type) {
                    ForEach(TriggerType.allCases, id: \.self) { type in
                        Text(loc(type.rawValue)).tag(type)
                    }
                }
                .labelsHidden()
                
                Spacer()
                Image(systemName: "arrow.right").foregroundColor(.secondary)
                Spacer()
                
                Picker(loc("Target"), selection: $trigger.nextStageId) {
                    Text(loc("Exit App")).tag("exit")
                    Divider()
                    ForEach(stages) { s in
                        Text(s.description.isEmpty ? s.id : s.description)
                            .tag(s.id)
                    }
                }
                .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

struct MediaThumbnailView: View {
    let source: String
    let type: StageType
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if source.isEmpty {
                    VStack {
                        Image(systemName: type == .video ? "video.badge.plus" : "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Select Media")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    if let thumb = thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                    } else if type == .image {
                        AsyncImage(url: URL(fileURLWithPath: source)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        // Video placeholder until loaded
                        ZStack {
                            Color.black.opacity(0.1)
                            ProgressView()
                        }
                    }
                }
                
                // Overlay an icon to indicate it is clickable
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "pencil.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                            .padding()
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear { loadThumbnail() }
            .onChange(of: source) { _ in loadThumbnail() }
        }
    }
    
    private func loadThumbnail() {
        guard !source.isEmpty else {
            thumbnail = nil
            return
        }
        
        if type == .video {
            let url = URL(fileURLWithPath: source)
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
                // Generate a thumbnail from the middle or beginning
                // Let's try 0 first, or slightly into it
                let time = CMTime(seconds: 0.1, preferredTimescale: 600)
                
                do {
                    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                    let uiImage = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self.thumbnail = uiImage
                    }
                } catch {
                    // Fallback to 0 if 0.1 failed (e.g. extremely short video)
                     do {
                        let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                        let uiImage = UIImage(cgImage: cgImage)
                        DispatchQueue.main.async {
                            self.thumbnail = uiImage
                        }
                    } catch {
                        print("Thumbnail gen error: \(error)")
                    }
                }
            }
        } else {
             thumbnail = nil // Let AsyncImage handle it
        }
    }
}
