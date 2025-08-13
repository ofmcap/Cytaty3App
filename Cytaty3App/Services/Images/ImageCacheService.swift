// Services/Images/ImageCacheService.swift
import UIKit

public final class ImageCacheService: ImageCacheServiceProtocol {
    private let fm = FileManager.default
    private let cache = NSCache<NSString, UIImage>()
    private lazy var coversDir: URL = {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("BookCovers", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }()

    public init() {}

    public func cachedImage(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    public func image(for urlString: String, cacheKey: String) async -> UIImage? {
        if let mem = cachedImage(for: cacheKey) { return mem }

        // jeśli istnieje plik na dysku pod tym kluczem
        let fileURL = coversDir.appendingPathComponent(cacheKey).appendingPathExtension("jpg")
        if let img = UIImage(contentsOfFile: fileURL.path) {
            cache.setObject(img, forKey: cacheKey as NSString)
            return img
        }

        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                cache.setObject(img, forKey: cacheKey as NSString)
                // zapisz na dysku
                if let jpg = img.jpegData(compressionQuality: 0.9) {
                    try? jpg.write(to: fileURL, options: .atomic)
                }
                return img
            }
        } catch {
            return nil
        }
        return nil
    }

    public func saveLocalCover(_ image: UIImage, for bookID: String) throws -> String {
        let filename = "cover_\(bookID).jpg"
        let url = coversDir.appendingPathComponent(filename)
        if let data = image.jpegData(compressionQuality: 0.9) {
            try data.write(to: url, options: .atomic)
            cache.setObject(image, forKey: filename as NSString)
            return filename
        } else {
            throw NSError(domain: "ImageCacheService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Nie udało się zakodować JPEG"])
        }
    }

    public func localCover(for filename: String) -> UIImage? {
        if let mem = cache.object(forKey: filename as NSString) { return mem }
        let url = coversDir.appendingPathComponent(filename)
        if let img = UIImage(contentsOfFile: url.path) {
            cache.setObject(img, forKey: filename as NSString)
            return img
        }
        return nil
    }
}
