// IssueCategory.swift
// ZOOMIN - Shared model file
// ⚠️ Shared file: Do not modify individually. All team members use the same file.
// Note: markerColor is defined in ZOOMINStyle.swift extension.

import SwiftUI

/// Urban infrastructure issue report category
/// ZOOMIN is a road/facility/construction safety platform, not just a complaint app.
enum IssueCategory: String, CaseIterable, Codable {
    case roadDamage             = "roadDamage"
    case sidewalkDamage         = "sidewalkDamage"
    case streetlightFailure     = "streetlightFailure"
    case drainageBlocked        = "drainageBlocked"
    case constructionSafetyRisk = "constructionSafetyRisk"
    case bridgeInfraRisk        = "bridgeInfraRisk"
    case other                  = "other"

    /// Display name shown on screen
    var displayName: String {
        switch self {
        case .roadDamage:             return "Road Damage"
        case .sidewalkDamage:         return "Sidewalk Damage"
        case .streetlightFailure:     return "Streetlight Failure"
        case .drainageBlocked:        return "Drainage Blocked"
        case .constructionSafetyRisk: return "Construction Risk"
        case .bridgeInfraRisk:        return "Bridge / Structure"
        case .other:                  return "Other"
        }
    }

    /// SF Symbols icon name
    var symbolName: String {
        switch self {
        case .roadDamage:             return "exclamationmark.triangle.fill"
        case .sidewalkDamage:         return "figure.walk"
        case .streetlightFailure:     return "lightbulb.slash.fill"
        case .drainageBlocked:        return "drop.triangle.fill"
        case .constructionSafetyRisk: return "helmet.fill"
        case .bridgeInfraRisk:        return "building.columns.fill"
        case .other:                  return "wrench.and.screwdriver.fill"
        }
    }
}
// Note: markerColor is defined in the extension IssueCategory block in ZOOMINStyle.swift.
