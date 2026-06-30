import Foundation
import UIKit

struct SearchResponse: Codable {
    let success: Bool
    let totalMatches: Int
    let socialProfiles: [SocialProfile]
    let otherMatches: [OtherMatch]
}

struct SocialProfile: Codable, Identifiable {
    let id = UUID()
    let platform: String
    let platformColor: String
    let url: String
    let username: String?
    let confidence: Int

    enum CodingKeys: String, CodingKey {
        case platform, platformColor, url, username, confidence
    }

    var platformURL: URL? { URL(string: url) }

    var confidenceLabel: String {
        switch confidence {
        case 80...: return "High"
        case 60..<80: return "Medium"
        case 40..<60: return "Low"
        default: return "Possible"
        }
    }
}

struct OtherMatch: Codable, Identifiable {
    let id = UUID()
    let url: String
    let confidence: Int

    enum CodingKeys: String, CodingKey {
        case url, confidence
    }

    var confidenceLabel: String {
        switch confidence {
        case 80...: return "High"
        case 60..<80: return "Medium"
        case 40..<60: return "Low"
        default: return "Possible"
        }
    }
}

struct APIError: Codable {
    let error: String
}

enum SearchError: LocalizedError {
    case noImage
    case networkError(String)
    case serverError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noImage: return "No image selected"
        case .networkError(let msg): return "Network error: \(msg)"
        case .serverError(let msg): return msg
        case .invalidResponse: return "Invalid response from server"
        }
    }
}

struct PlatformColor {
    static func color(for hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if let int = Int(hex, radix: 16) {
            let r = CGFloat((int >> 16) & 0xFF) / 255
            let g = CGFloat((int >> 8) & 0xFF) / 255
            let b = CGFloat(int & 0xFF) / 255
            return UIColor(red: r, green: g, blue: b, alpha: 1)
        }
        return .gray
    }
}
