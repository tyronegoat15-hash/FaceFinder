import Foundation
import UIKit

class FaceSearchService {
    static let shared = FaceSearchService()

    private var baseURL: String {
        get { UserDefaults.standard.string(forKey: "server_url") ?? "http://localhost:3000" }
        set { UserDefaults.standard.set(newValue, forKey: "server_url") }
    }

    func search(image: UIImage) async throws -> SearchResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.85) ?? image.pngData() else {
            throw SearchError.noImage
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: URL(string: "\(baseURL)/api/search")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.invalidResponse
        }

        if httpResponse.statusCode == 413 {
            throw SearchError.serverError("Image too large. Try a smaller photo.")
        }

        if httpResponse.statusCode != 200 {
            if let errResp = try? JSONDecoder().decode(APIError.self, from: data) {
                throw SearchError.serverError(errResp.error)
            }
            throw SearchError.serverError("Server error (HTTP \(httpResponse.statusCode))")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(SearchResponse.self, from: data)
    }

    func updateServerURL(_ url: String) {
        baseURL = url
    }

    func getServerURL() -> String {
        return baseURL
    }
}
