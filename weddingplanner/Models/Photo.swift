import Foundation
import SwiftData
import SwiftUI

enum PhotoCategory: String, Codable, CaseIterable {
    case venue = "Venue"
    case dress = "Dress"
    case flowers = "Flowers"
    case cake = "Cake"
    case decor = "Decor"
    case rings = "Rings"
    case invitations = "Invitations"
    case hair = "Hair & Makeup"
    case inspiration = "Inspiration"
    case other = "Other"

    var icon: String {
        switch self {
        case .venue: return "building.2"
        case .dress: return "figure.dress.line.vertical.figure"
        case .flowers: return "camera.macro"
        case .cake: return "birthday.cake"
        case .decor: return "sparkles"
        case .rings: return "circle.circle"
        case .invitations: return "envelope"
        case .hair: return "comb"
        case .inspiration: return "heart.text.square"
        case .other: return "photo"
        }
    }

    var color: String {
        switch self {
        case .venue: return "8B7355"
        case .dress: return "E8C4B8"
        case .flowers: return "D4A5B0"
        case .cake: return "F5D5C8"
        case .decor: return "C8A89C"
        case .rings: return "B8A398"
        case .invitations: return "A8B8C8"
        case .hair: return "E8B8D8"
        case .inspiration: return "FFB5BA"
        case .other: return "C4C4C4"
        }
    }
}

@Model
final class Photo {
    var id: UUID
    var imageData: Data?
    var thumbnailData: Data?
    var category: PhotoCategory
    var title: String
    var notes: String?
    var sourceURL: String?
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship var wedding: Wedding?
    @Relationship var vendor: Vendor?

    init(
        imageData: Data? = nil,
        category: PhotoCategory,
        title: String,
        notes: String? = nil,
        sourceURL: String? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.category = category
        self.title = title
        self.notes = notes
        self.sourceURL = sourceURL
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()

        // Generate thumbnail
        if let imageData = imageData {
            self.thumbnailData = Photo.generateThumbnail(from: imageData)
        }
    }

    static func generateThumbnail(from imageData: Data, maxSize: CGFloat = 200) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }

        let size = image.size
        let scale = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail?.jpegData(compressionQuality: 0.7)
    }
}