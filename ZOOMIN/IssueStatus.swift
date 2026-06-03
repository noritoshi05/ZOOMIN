// IssueStatus.swift
// ZOOMIN - Shared model file
// ⚠️ Shared file: Do not modify individually. All team members use the same file.
// Note: symbolName, badgeColor, badgeTextColor are defined in ZOOMINStyle.swift extension.

import SwiftUI

/// Report processing status
enum IssueStatus: String, CaseIterable, Codable {
    case received   = "received"
    case reviewing  = "reviewing"
    case inProgress = "inProgress"
    case completed  = "completed"

    /// Display name shown on screen
    var displayName: String {
        switch self {
        case .received:   return "Received"
        case .reviewing:  return "Reviewing"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        }
    }

    /// Next available statuses for admin
    var nextStatuses: [IssueStatus] {
        switch self {
        case .received:   return [.reviewing, .inProgress]
        case .reviewing:  return [.inProgress]
        case .inProgress: return [.completed]
        case .completed:  return []
        }
    }
}
// Note: symbolName / badgeColor / badgeTextColor are defined in
//       the extension IssueStatus block in ZOOMINStyle.swift.
