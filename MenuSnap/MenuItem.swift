//
//  MenuItem.swift
//  MenuSnap
//
//  Created by Eric Stimmel on 1/10/26.
//

import Foundation

struct MenuItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let healthScore: Int
    let healthReason: String
    let calories: String?

    init(id: UUID = UUID(), name: String, description: String? = nil, healthScore: Int, healthReason: String, calories: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.healthScore = max(1, min(10, healthScore))
        self.healthReason = healthReason
        self.calories = calories
    }

    var healthCategory: HealthCategory {
        switch healthScore {
        case 8...10:
            return .healthy
        case 5...7:
            return .moderate
        default:
            return .lessHealthy
        }
    }
}

enum HealthCategory {
    case healthy
    case moderate
    case lessHealthy

    var color: String {
        switch self {
        case .healthy:
            return "green"
        case .moderate:
            return "yellow"
        case .lessHealthy:
            return "red"
        }
    }

    var label: String {
        switch self {
        case .healthy:
            return "Healthy"
        case .moderate:
            return "Moderate"
        case .lessHealthy:
            return "Less Healthy"
        }
    }
}
