//
//  MenuAnalysisViewModel.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import Foundation
import UIKit

@Observable
class MenuAnalysisViewModel {
    var state: AnalysisState = .idle
    var menuItems: [MenuItem] = []
    var errorMessage: String?

    enum AnalysisState {
        case idle
        case loading
        case success
        case error
    }

    func analyzeMenu(image: UIImage) async {
        await MainActor.run {
            state = .loading
            errorMessage = nil
        }

        do {
            let items = try await ClaudeAPIService.shared.analyzeMenu(image: image)

            await MainActor.run {
                // Sort by health score (highest first)
                menuItems = items.sorted { $0.healthScore > $1.healthScore }
                state = menuItems.isEmpty ? .error : .success
                if menuItems.isEmpty {
                    errorMessage = "No menu items could be identified. Try a clearer photo."
                }
            }
        } catch {
            await MainActor.run {
                state = .error
                errorMessage = error.localizedDescription
            }
        }
    }

    func retry(image: UIImage) async {
        await analyzeMenu(image: image)
    }
}
