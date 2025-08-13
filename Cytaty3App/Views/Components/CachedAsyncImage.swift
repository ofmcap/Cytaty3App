// Views/Components/CachedAsyncImage.swift
import SwiftUI
import UIKit

struct CachedAsyncImage: View {
    let urlString: String?
    let cacheKey: String
    let imageCache: ImageCacheServiceProtocol
    let size: CGSize

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let img = uiImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Color.secondary.opacity(0.1))
                    .overlay(Image(systemName: "book").foregroundColor(.secondary))
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: urlString) {
            guard let urlString else { return }
            if let img = await imageCache.image(for: urlString, cacheKey: cacheKey) {
                uiImage = img
            }
        }
    }
}
