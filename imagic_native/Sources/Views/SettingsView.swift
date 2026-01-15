
import SwiftUI

struct SettingsView: View {
    @ObservedObject var engine: MagicEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Stages")) {
                    ForEach(engine.config.stages) { stage in
                        NavigationLink(destination: StageEditor(stage: stage, engine: engine)) {
                            HStack {
                                Text(stage.description.isEmpty ? stage.id : stage.description)
                                Spacer()
                                Text(stage.type.rawValue).foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        // engine.removeStage(at: indexSet) // To Implement
                    }
                    
                    Button("Add New Stage") {
                        let newStage = MagicStage(description: "New Stage")
                        engine.saveStage(newStage)
                    }
                }
                
                Section(header: Text("Global Config")) {
                    HStack {
                        Text("Blow Threshold (dB)")
                        Spacer()
                        TextField("-10.0", value: $engine.config.blowThreshold, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct StageEditor: View {
    @State var stage: MagicStage
    var engine: MagicEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Info")) {
                TextField("Description", text: $stage.description)
                Picker("Type", selection: $stage.type) {
                    Text("Video").tag(StageType.video)
                    Text("Image").tag(StageType.image)
                }
                TextField("Source Path", text: $stage.source)
            }
            
            Section(header: Text("Playback")) {
                Picker("Mode", selection: $stage.mode) {
                    Text("One Shot").tag(PlaybackMode.oneShot)
                    Text("Loop").tag(PlaybackMode.loop)
                }
                Toggle("Show Clock", isOn: $stage.showTime)
            }
            
            Section(header: Text("Triggers")) {
                ForEach(stage.triggers.indices, id: \.self) { i in
                    let trigger = stage.triggers[i]
                    HStack {
                        Text(trigger.type.rawValue)
                        Spacer()
                        Text("-> \(trigger.nextStageId)")
                    }
                }
                Button("Add Trigger (Simple)") {
                    // Simple logic for MVP demo
                    stage.triggers.append(MagicTrigger(type: .tap1, nextStageId: "exit"))
                }
            }
        }
        .navigationTitle("Edit Stage")
        .navigationBarItems(trailing: Button("Save") {
            engine.saveStage(stage)
            presentationMode.wrappedValue.dismiss()
        })
    }
}
