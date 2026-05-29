// Issue.swift
// ZOOMIN - Shared model file
// ⚠️ 팀 공용 파일: 이 파일은 모든 팀원이 동일하게 사용합니다. 절대 수정하지 마세요.

import Foundation
import UIKit

/// ZOOMIN 앱의 핵심 신고 데이터 모델
struct Issue: Identifiable, Codable, Hashable {

    // MARK: - 기본 속성
    let id: UUID
    var title: String
    var category: IssueCategory
    var description: String

    // MARK: - 위치
    var latitude: Double
    var longitude: Double

    // MARK: - 사진
    /// 앱 번들에 포함된 샘플 이미지 이름 (fallback용)
    var imageName: String?
    /// 카메라로 찍은 실제 사진 데이터 (로컬 저장)
    /// SwiftUI 사용법: if let uiImg = issue.uiImage { Image(uiImage: uiImg) }
    var photoData: Data?

    // MARK: - 지역 주민 참여
    var supportCount: Int

    // MARK: - 우선순위 요소 (1~5점)
    var safetyRisk: Int     // 안전 위험도
    var urgency: Int        // 긴급도
    var publicImpact: Int   // 공공 영향도

    // MARK: - 처리 상태
    var status: IssueStatus

    // MARK: - 날짜
    var reportDate: Date
    var completionDate: Date?

    // MARK: - 완료 보고
    var completionSummary: String?

    // MARK: - 보상
    var rewardPoints: Int

    // MARK: - 내 신고 여부
    var isMyReport: Bool

    // MARK: - 생성자
    init(
        id: UUID = UUID(),
        title: String,
        category: IssueCategory,
        description: String,
        latitude: Double,
        longitude: Double,
        imageName: String? = nil,
        photoData: Data? = nil,
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

    // MARK: - Computed: 지지 점수 (조작 방지를 위해 최대 3점으로 제한)
    /// 0~5 건 → 0점 / 6~10 건 → 1점 / 11~20 건 → 2점 / 21+ 건 → 3점
    var supportScore: Int {
        switch supportCount {
        case 0...5:   return 0
        case 6...10:  return 1
        case 11...20: return 2
        default:      return 3
        }
    }

    // MARK: - Computed: 우선순위 총점 (최대 18점)
    var priorityScore: Int {
        safetyRisk + urgency + publicImpact + supportScore
    }

    // MARK: - Computed: 우선순위 등급
    var priorityLevel: PriorityLevel {
        switch priorityScore {
        case 13...18: return .high
        case 8...12:  return .medium
        default:      return .low
        }
    }

    // MARK: - Computed: UIImage 변환 헬퍼
    var uiImage: UIImage? {
        guard let data = photoData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - 우선순위 등급
enum PriorityLevel: String, Codable, Hashable {
    case high   = "High"
    case medium = "Medium"
    case low    = "Low"

    var displayName: String {
        switch self {
        case .high:   return "높음"
        case .medium: return "보통"
        case .low:    return "낮음"
        }
    }
}
