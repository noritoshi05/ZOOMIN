// IssueCategory.swift
// ZOOMIN - Shared model file
// ⚠️ 팀 공용 파일: 이 파일은 모든 팀원이 동일하게 사용합니다.
// 주의: markerColor는 ZOOMINStyle.swift extension에서 정의됩니다.

import SwiftUI

/// 도시 인프라 유지관리 신고 카테고리
/// ZOOMIN은 단순 민원앱이 아닌 도로·시설물·건설 안전 특화 플랫폼입니다.
enum IssueCategory: String, CaseIterable, Codable {
    case roadDamage             = "roadDamage"           // 도로 파손
    case sidewalkDamage         = "sidewalkDamage"       // 보도 파손
    case streetlightFailure     = "streetlightFailure"   // 가로등 고장
    case drainageBlocked        = "drainageBlocked"      // 배수구 막힘 / 침수 위험
    case constructionSafetyRisk = "constructionSafetyRisk" // 공사 안전 위험
    case bridgeInfraRisk        = "bridgeInfraRisk"      // 교량·고가 구조물 위험
    case other                  = "other"                // 기타 시설물

    /// 화면에 표시할 한국어 이름
    var displayName: String {
        switch self {
        case .roadDamage:             return "도로 파손"
        case .sidewalkDamage:         return "보도 파손"
        case .streetlightFailure:     return "가로등 고장"
        case .drainageBlocked:        return "배수 불량"
        case .constructionSafetyRisk: return "공사 안전 위험"
        case .bridgeInfraRisk:        return "교량·구조물"
        case .other:                  return "기타 시설물"
        }
    }

    /// SF Symbols 아이콘 이름
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
// 참고: markerColor 는 ZOOMINStyle.swift 의 extension IssueCategory 블록에서 정의됩니다.
