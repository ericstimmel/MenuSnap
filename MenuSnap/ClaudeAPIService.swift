//
//  ClaudeAPIService.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import Foundation
import UIKit

class ClaudeAPIService {
    static let shared = ClaudeAPIService()

    // TODO: Replace with your actual Claude API key
    private let apiKey = "YOUR_API_KEY_HERE"
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514" //claude-haiku-3-5-20241022 is cheaper and can still work

    private init() {}

    private let maxImageSize: Int = 3 * 1024 * 1024  // 3MB to stay under 5MB after base64 encoding (+33%)

    func analyzeMenu(image: UIImage) async throws -> [MenuItem] {
        let processedImage = resizeImageIfNeeded(image, maxDimension: 2500)

        guard let imageData = compressImage(processedImage, maxSize: maxImageSize) else {
            throw APIError.imageConversionFailed
        }

        let base64Image = imageData.base64EncodedString()

        let requestBody = buildRequestBody(base64Image: base64Image)

        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw APIError.apiError(message)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }

        return try parseResponse(data: data)
    }

    private func buildRequestBody(base64Image: String) -> [String: Any] {
        let prompt = """
        IMPORTANT: Extract EVERY menu item visible in this image. Do not skip any items.

        Carefully scan the ENTIRE menu from top to bottom, left to right. Include ALL:
        - Appetizers, starters, soups, salads
        - Main courses, entrees, sandwiches, burgers
        - Sides, extras, add-ons
        - Desserts, drinks, beverages
        - Any specials or featured items

        For EACH item found:
        1. Item name (exactly as shown)
        2. Description if visible (or null)
        3. Health score 1-10 (10 = healthiest)
        4. Brief health reason
        5. Estimated calories (or null)

        Health scoring factors:
        - Cooking method (fried=lower, grilled/steamed=higher)
        - Vegetables and lean proteins = higher
        - Heavy cream, butter, fried foods = lower
        - Large portions = lower

        Respond ONLY with a JSON array. Format:
        [{"name": "Item", "description": null, "healthScore": 7, "healthReason": "reason", "calories": null}]

        Return [] only if the image is unreadable. Otherwise, extract EVERYTHING visible.
        """

        return [
            "model": model,
            "max_tokens": 8192,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
    }

    private func parseResponse(data: Data) throws -> [MenuItem] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIError.parsingFailed
        }

        // Extract and clean JSON from the response text
        let jsonText = extractJSON(from: text)

        guard let jsonData = jsonText.data(using: .utf8) else {
            throw APIError.parsingFailed
        }

        // Try to parse as array of dictionaries for more flexible handling
        guard let rawItems = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            print("Failed to parse JSON: \(jsonText.prefix(500))")
            throw APIError.parsingFailed
        }

        return rawItems.compactMap { dict -> MenuItem? in
            guard let name = dict["name"] as? String else { return nil }

            // Handle healthScore as either Int or String
            let healthScore: Int
            if let score = dict["healthScore"] as? Int {
                healthScore = score
            } else if let scoreString = dict["healthScore"] as? String,
                      let score = Int(scoreString) {
                healthScore = score
            } else {
                healthScore = 5 // Default if missing
            }

            let healthReason = dict["healthReason"] as? String ?? "No details available"
            let description = dict["description"] as? String
            let calories = dict["calories"] as? String

            return MenuItem(
                name: name,
                description: description,
                healthScore: healthScore,
                healthReason: healthReason,
                calories: calories
            )
        }
    }

    private func extractJSON(from text: String) -> String {
        // Try to find JSON array in the response
        guard let startIndex = text.firstIndex(of: "[") else {
            return "[]"
        }

        // Find the last complete object by looking for }]
        if let endIndex = text.lastIndex(of: "]") {
            var jsonString = String(text[startIndex...endIndex])

            // Fix truncated JSON - if it doesn't end properly, try to close it
            if !jsonString.hasSuffix("]") {
                // Find last complete object
                if let lastBrace = jsonString.lastIndex(of: "}") {
                    jsonString = String(jsonString[...lastBrace]) + "]"
                }
            }

            return jsonString
        }

        return "[]"
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func compressImage(_ image: UIImage, maxSize: Int) -> Data? {
        var compression: CGFloat = 0.8
        let minCompression: CGFloat = 0.1

        guard var imageData = image.jpegData(compressionQuality: compression) else {
            return nil
        }

        // Progressively reduce quality until under size limit
        while imageData.count > maxSize && compression > minCompression {
            compression -= 0.1
            if let newData = image.jpegData(compressionQuality: compression) {
                imageData = newData
            }
        }

        return imageData.count <= maxSize ? imageData : nil
    }
}

// DTO for decoding API response
private struct MenuItemDTO: Codable {
    let name: String
    let description: String?
    let healthScore: Int
    let healthReason: String
    let calories: String?
}

enum APIError: LocalizedError {
    case imageConversionFailed
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process the image"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server error (code: \(code))"
        case .apiError(let message):
            return message
        case .parsingFailed:
            return "Failed to parse menu items"
        }
    }
}
