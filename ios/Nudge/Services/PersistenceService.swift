import Foundation

/// Everything the user creates survives relaunch — the life log, symptom
/// logs, held moments, the visit guide, and what the companion remembers.
/// One JSON document in the app's own container; private, exportable,
/// deletable. Persona fixtures stay code-side and merge on load.
struct SanoUserData: Codable {
    var pathway: String = ""
    var entries: [CareEntry] = []
    var logs: [SymptomLog] = []
    var memories: [MemoryGlimpse] = []
    var guideItems: [GuideItem] = []
    var memoryNotes: [MemoryItem] = []
    // v5 Care hub — everything the user creates in Care survives relaunch.
    var threads: [MessageThread] = []
    var requests: [CareRequest] = []
    var documents: [CareDocument] = []
    /// Stable keys of bills the user has paid (paid handoff is user-driven).
    var paidBillKeys: [String] = []
    /// Care-plan goals the user turned into journeys (§4.4.5).
    var derivedJourneyGoals: [String] = []
}

enum PersistenceService {
    private static var fileURL: URL {
        URL.documentsDirectory.appendingPathComponent("sano_user_data.json")
    }

    static func load() -> SanoUserData? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(SanoUserData.self, from: data)
        } catch {
            print("[Sano] user data decode failed: \(error.localizedDescription)")
            return nil
        }
    }

    static func save(_ data: SanoUserData) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let encoded = try encoder.encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            print("[Sano] user data save failed: \(error.localizedDescription)")
        }
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
