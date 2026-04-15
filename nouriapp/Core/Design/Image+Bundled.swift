//
//  Image+Bundled.swift
//  nouriapp
//

import SwiftUI
import UIKit

extension Image {
    /// Loads an image from the asset catalog or the bundle, matching React Native's bundling behaviour.
    static func bundled(_ name: String) -> Image {
        // 1. Try Assets Catalog first (best performance, handles symbols)
        if let image = UIImage(named: name) {
            return Image(uiImage: image)
        }

        // 2. Try raw bundle paths next
        let urls = [
            Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "assets"),
            Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "assets"),
            Bundle.main.url(forResource: name, withExtension: "png"),
            Bundle.main.url(forResource: name, withExtension: "svg"),
        ].compactMap { $0 }

        for url in urls {
            if let image = UIImage(contentsOfFile: url.path) {
                return Image(uiImage: image)
            }
        }
        
        // 3. Last resort placeholder
        return Image(systemName: "photo")
    }
}
