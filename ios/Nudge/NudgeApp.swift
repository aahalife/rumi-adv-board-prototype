import SwiftUI

@main
struct NudgeApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NudgeFonts.registerAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .tint(Theme.warm)
                .preferredColorScheme(model.colorSchemeOverride)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if model.musicOn, let bed = SoundEngine.shared.currentBed {
                    SoundEngine.shared.playBed(bed, fade: 1.8)
                }
            case .background:
                SoundEngine.shared.pauseBed(fade: 0.6)
            default:
                break
            }
        }
    }
}
