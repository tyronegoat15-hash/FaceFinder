import SwiftUI

struct SearchResponse: Codable {
    let success: Bool
    let totalMatches: Int
    let socialProfiles: [SocialProfile]
    let criminalRecords: [CriminalRecord]
    let otherMatches: [OtherMatch]
}

struct SocialProfile: Codable, Identifiable {
    let id = UUID()
    let platform: String
    let icon: String
    let color: String
    let url: String
    let username: String?
    let confidence: Int

    enum CodingKeys: String, CodingKey { case platform, icon, color, url, username, confidence }
    var platformURL: URL? { URL(string: url) }

    var confidenceLabel: String {
        if confidence >= 80 { return "High" }
        if confidence >= 60 { return "Medium" }
        if confidence >= 40 { return "Low" }
        return "Possible"
    }

    var confidenceColor: Color {
        if confidence >= 80 { return .green }
        if confidence >= 60 { return .yellow }
        if confidence >= 40 { return .orange }
        return .gray
    }
}

struct CriminalRecord: Codable, Identifiable {
    let id = UUID()
    let source: String
    let type: String
    let url: String
    let confidence: Int

    enum CodingKeys: String, CodingKey { case source, type, url, confidence }

    var color: Color {
        if type.contains("Sex") { return .red }
        if type.contains("Arrest") || type.contains("Mugshot") { return .orange }
        return .yellow
    }
}

struct OtherMatch: Codable, Identifiable {
    let id = UUID()
    let url: String
    let confidence: Int

    enum CodingKeys: String, CodingKey { case url, confidence }
}

struct HealthResponse: Codable {
    let status: String
    let version: String?
}

struct APIError: Codable { let error: String }

enum AppError: LocalizedError {
    case noImage, network(String), server(String), invalidResponse
    var errorDescription: String? {
        switch self {
        case .noImage: return "No image selected"
        case .network(let m): return "Network error: \(m)"
        case .server(let m): return m
        case .invalidResponse: return "Invalid server response"
        }
    }
}

class FaceSearchService: ObservableObject {
    static let shared = FaceSearchService()

    @Published var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: "server_url") }
    }

    private init() {
        serverURL = UserDefaults.standard.string(forKey: "server_url") ?? "http://localhost:3000"
    }

    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(serverURL)/api/health") else { return false }
        return (try? await URLSession.shared.data(from: url).0) != nil
    }

    func search(image: UIImage) async throws -> SearchResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else { throw AppError.noImage }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: URL(string: "\(serverURL)/api/search")!)
        req.httpMethod = "POST"; req.timeoutInterval = 120
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw AppError.invalidResponse }
        if http.statusCode == 413 { throw AppError.server("Image too large") }
        if http.statusCode != 200 {
            if let e = try? JSONDecoder().decode(APIError.self, from: respData) { throw AppError.server(e.error) }
            throw AppError.server("HTTP \(http.statusCode)")
        }
        return try JSONDecoder().decode(SearchResponse.self, from: respData)
    }
}
