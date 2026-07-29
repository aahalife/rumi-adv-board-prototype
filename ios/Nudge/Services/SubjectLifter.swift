import UIKit
import Vision
import CoreImage

/// Lifts the subject out of a bundled studio photograph so meals, moves and
/// meds float directly on the canvas like objects set on a table — the
/// magazine look. Vision's foreground-instance mask does the cutting; results
/// are cached in memory and on disk so each image is lifted exactly once.
final class SubjectLifter {
    static let shared = SubjectLifter()

    private let memory = NSCache<NSString, UIImage>()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init() {
        memory.countLimit = 60
    }

    /// Returns the subject-only image for a bundled asset, or nil when no
    /// subject could be found (callers fall back to the original).
    func lifted(named name: String) async -> UIImage? {
        if let hit = memory.object(forKey: name as NSString) { return hit }

        if let disk = Self.loadFromDisk(name: name) {
            memory.setObject(disk, forKey: name as NSString)
            return disk
        }

        if let task = inFlight[name] { return await task.value }

        guard let source = UIImage(named: name) else { return nil }
        let task = Task<UIImage?, Never> {
            let result = await Self.performLift(source)
            if let result {
                Self.saveToDisk(result, name: name)
            }
            return result
        }
        inFlight[name] = task
        let result = await task.value
        inFlight[name] = nil
        if let result { memory.setObject(result, forKey: name as NSString) }
        return result
    }

    // MARK: - Vision

    nonisolated private static func performLift(_ image: UIImage) async -> UIImage? {
        await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let cgImage = image.cgImage else { return nil }
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let observation = request.results?.first,
                      !observation.allInstances.isEmpty
                else { return nil }
                let buffer = try observation.generateMaskedImage(
                    ofInstances: observation.allInstances,
                    from: handler,
                    croppedToInstancesExtent: true
                )
                let ciImage = CIImage(cvPixelBuffer: buffer)
                let context = CIContext()
                guard let output = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
                return UIImage(cgImage: output, scale: image.scale, orientation: .up)
            } catch {
                print("[Sano] subject lift failed: \(error.localizedDescription)")
                return nil
            }
        }.value
    }

    // MARK: - Disk cache

    nonisolated private static func cacheURL(for name: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return nil }
        let dir = caches.appendingPathComponent("lifted", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(name).png")
    }

    nonisolated private static func loadFromDisk(name: String) -> UIImage? {
        guard let url = cacheURL(for: name),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    nonisolated private static func saveToDisk(_ image: UIImage, name: String) {
        guard let url = cacheURL(for: name),
              let data = image.pngData()
        else { return }
        try? data.write(to: url)
    }
}

import SwiftUI

/// A bundled studio image rendered as a floating lifted subject with a soft
/// contact shadow — the object sits on the canvas, not in a box. Falls back
/// to the original photo in a rounded mask while the lift resolves.
struct LiftedImage: View {
    let name: String
    var shadowOpacity: Double = 0.3

    @State private var lifted: UIImage? = nil
    @State private var resolved = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Contact shadow under the subject.
                Ellipse()
                    .fill(Theme.shadow.opacity(resolved ? shadowOpacity : 0))
                    .frame(width: geo.size.width * 0.72, height: geo.size.height * 0.13)
                    .blur(radius: 10)
                    .offset(y: geo.size.height * 0.42)

                if let lifted {
                    Image(uiImage: lifted)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.opacity)
                } else {
                    // Soft-masked original while Vision works.
                    Image(name)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipShape(.rect(cornerRadius: geo.size.width * 0.24))
                        .opacity(0.92)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .task(id: name) {
            resolved = false
            let image = await SubjectLifter.shared.lifted(named: name)
            withAnimation(NudgeSpring.gentle) {
                lifted = image
                resolved = image != nil
            }
        }
        .accessibilityHidden(true)
    }
}
