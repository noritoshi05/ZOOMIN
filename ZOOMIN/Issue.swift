// Issue.swift
// ZOOMIN - Shared model file
// ⚠️ Shared file: Do not modify individually. All team members use the same file.

import Foundation
import UIKit

/// Core report data model for the ZOOMIN app
struct Issue: Identifiable, Codable, Hashable {
    
    // MARK: - Basic Properties
    let id: UUID
    var title: String
    var category: IssueCategory
    var description: String
    
    // MARK: - Location
    var latitude: Double
    var longitude: Double
    
    // MARK: - Photo
    /// Sample image name included in app bundle (fallback)
    var imageName: String?
    /// Actual photo data taken by camera (local storage)
    /// SwiftUI usage: if let uiImg = issue.uiImage { Image(uiImage: uiImg) }
    var photoData: Data?
    var photoURL : String?
    
    // MARK: - Community Support
    var supportCount: Int
    
    // MARK: - Priority Factors (1~5 points each)
    var safetyRisk: Int     // Safety risk level
    var urgency: Int        // Urgency level
    var publicImpact: Int   // Public impact level
    
    // MARK: - Processing Status
    var status: IssueStatus
    
    // MARK: - Dates
    var reportDate: Date
    var completionDate: Date?
    
    // MARK: - Completion Report
    var completionSummary: String?
    
    // MARK: - Reward
    var rewardPoints: Int
    
    // MARK: - My Report Flag
    var isMyReport: Bool
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        title: String,
        category: IssueCategory,
        description: String,
        latitude: Double,
        longitude: Double,
        imageName: String? = nil,
        photoData: Data? = nil,
        photoURL : String? = nil,
        supportCount: Int = 0,
        safetyRisk: Int,
        urgency: Int,
        publicImpact: Int,
        status: IssueStatus = .received,
        reportDate: Date = Date(),
        completionDate: Date? = nil,
        completionSummary: String? = nil,
        rewardPoints: Int = 10,
        isMyReport: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.imageName = imageName
        self.photoData = photoData
        self.photoURL = photoURL
        self.supportCount = supportCount
        self.safetyRisk = safetyRisk
        self.urgency = urgency
        self.publicImpact = publicImpact
        self.status = status
        self.reportDate = reportDate
        self.completionDate = completionDate
        self.completionSummary = completionSummary
        self.rewardPoints = rewardPoints
        self.isMyReport = isMyReport
    }
    
    // MARK: - Computed: Support score (capped at 3 to prevent manipulation)
    /// 0-5 → 0pts / 6-10 → 1pt / 11-20 → 2pts / 21+ → 3pts
    var supportScore: Int {
        switch supportCount {
        case 0...5:   return 0
        case 6...10:  return 1
        case 11...20: return 2
        default:      return 3
        }
    }
    
    // MARK: - Computed: Total priority score (max 18)
    var priorityScore: Int {
        safetyRisk + urgency + publicImpact + supportScore
    }
    
    // MARK: - Computed: Priority level
    var priorityLevel: PriorityLevel {
        switch priorityScore {
        case 13...18: return .high
        case 8...12:  return .medium
        default:      return .low
        }
    }
    
    // MARK: - Computed: UIImage conversion helper
    var uiImage: UIImage? {
        if let data = photoData { return UIImage(data: data) }
        if let urlString = photoURL,
           let url = URL(string: urlString),
           let data = try? Data(contentsOf: url) { return UIImage(data: data) }
        return nil
    }
    
    // MARK: - Priority Level
    enum PriorityLevel: String, Codable, Hashable {
        case high   = "High"
        case medium = "Medium"
        case low    = "Low"
        
        var displayName: String {
            switch self {
            case .high:   return "High"
            case .medium: return "Medium"
            case .low:    return "Low"
            }
        }
    }
}
