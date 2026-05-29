// IssueStatus.swift
// ZOOMIN - Shared model file
// ⚠️ 팀 공용 파일: 이 파일은 모든 팀원이 동일하게 사용합니다.
// 주의: symbolName, badgeColor, badgeTextColor는 ZOOMINStyle.swift extension에서 정의됩니다.

import SwiftUI

/// 신고 처리 상태
enum IssueStatus: String, CaseIterable, Codable {
    case received   = "received"
    case reviewing  = "reviewing"
    case inProgress = "inProgress"
    case completed  = "completed"

    /// 화면에 표시할 한국어 이름
    var displayName: String {
        switch self {
        case .received:   return "접수됨"
        case .reviewing:  return "검토 중"
        case .inProgress: return "처리 중"
        case .completed:  return "완료"
        }
    }

    /// 관리자가 선택 가능한 다음 상태들
    var nextStatuses: [IssueStatus] {
        switch self {
        case .received:   return [.reviewing, .inProgress]
        case .reviewing:  return [.inProgress]
        case .inProgress: return [.completed]
        case .completed:  return []
        }
    }
}
// 참고: symbolName / badgeColor / badgeTextColor 는 ZOOMINStyle.swift 의
//      extension IssueStatus 블록에서 정의됩니다.
