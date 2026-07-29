import Foundation

/// Build-time configuration injected from the Rork project environment.
/// These are public client-tier values (same tier as a publishable key).
enum AppConfig {
    static let toolkitURL = Config.EXPO_PUBLIC_TOOLKIT_URL.isEmpty ? "https://toolkit.rork.com" : Config.EXPO_PUBLIC_TOOLKIT_URL
    static let toolkitKey = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
    static let functionsURL = Config.EXPO_PUBLIC_RORK_FUNCTIONS_URL.isEmpty ? "https://nudge-plus-d9rx5y5-backend.rork.app" : Config.EXPO_PUBLIC_RORK_FUNCTIONS_URL
    /// The model behind the companion. Sonnet 4.6 — fast enough to keep voice
    /// turns snappy while staying warm and precise.
    static let chatModel = "anthropic/claude-sonnet-4.6"
    /// The companion's spoken voice is held by the backend proxy so the raw
    /// ElevenLabs voice/key never ship in the app bundle.
    static let voicePath = "/voice/tts"
}
