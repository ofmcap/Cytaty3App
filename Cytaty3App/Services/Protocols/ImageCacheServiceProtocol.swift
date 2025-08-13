// Services/Protocols/ImageCacheServiceProtocol.swift
import UIKit

public protocol ImageCacheServiceProtocol {
    func cachedImage(for key: String) -> UIImage?
    func image(for urlString: String, cacheKey: String) async -> UIImage?
    func saveLocalCover(_ image: UIImage, for bookID: String) throws -> String // returns filename
    func localCover(for filename: String) -> UIImage?
}
