//
//  AnimatedGIFImage.swift
//  nouriapp
//
//  UIViewRepresentable that plays animated GIFs using ImageIO with thumbnail decoding.
//  Frames are decoded at display size (~128px) not source size (640px) — ~25x faster.
//

import SwiftUI
import UIKit
import ImageIO

// Global cache — keyed by name, value is the ready-to-use animated UIImage
private let gifCache = NSCache<NSString, UIImage>()

struct AnimatedGIFImage: UIViewRepresentable {
    let name: String
    var size: CGFloat = 36

    // MARK: - Public preload (call from ContentView at launch)

    @discardableResult
    static nonisolated func preload(named name: String) -> UIImage? {
        decodeGIF(named: name)
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true

        if let cached = gifCache.object(forKey: name as NSString) {
            iv.image = cached             // instant — already decoded
        } else {
            DispatchQueue.global(qos: .userInitiated).async {
                let img = AnimatedGIFImage.decodeGIF(named: name)
                DispatchQueue.main.async { iv.image = img }
            }
        }
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIImageView, context: Context) -> CGSize? {
        CGSize(width: size, height: size)
    }

    // MARK: - Thumbnail-based GIF decode (decodes at screen size, not source size)

    private static func decodeGIF(named name: String) -> UIImage? {
        if let cached = gifCache.object(forKey: name as NSString) { return cached }

        guard let data = gifData(named: name),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration: Double = 0

        // Ask ImageIO to decode at max 128px — avoids processing 640×640 per frame
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 128,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
        ]

        for i in 0 ..< count {
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, thumbOptions as CFDictionary)
            else { continue }

            totalDuration += frameDuration(source: source, index: i)
            frames.append(UIImage(cgImage: cgImage))
        }

        guard !frames.isEmpty else { return nil }
        let animated = UIImage.animatedImage(with: frames, duration: totalDuration)
        if let animated { gifCache.setObject(animated, forKey: name as NSString) }
        return animated
    }

    private static func gifData(named name: String) -> Data? {
        for sub in ["assets", nil] as [String?] {
            if let url = Bundle.main.url(forResource: name, withExtension: "gif", subdirectory: sub),
               let data = try? Data(contentsOf: url) { return data }
        }
        return nil
    }

    private static func frameDuration(source: CGImageSource, index: Int) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gif   = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] else { return 0.1 }
        if let d = gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double, d > 0 { return d }
        if let d = gif[kCGImagePropertyGIFDelayTime as String] as? Double, d > 0 { return d }
        return 0.1
    }
}
