import SwiftUI

// ============================================================
//  ZOOMINStyle.swift
//  공용 디자인 시스템 — 모든 멤버가 이 파일을 공유하세요
//  PINGO 마스코트 + 디자인 가이드 기반
// ============================================================

// MARK: - 브랜드 컬러
extension Color {
    // 메인 브랜드
    static let zoominBlue      = Color(hex: "#2B7FE0")   // 메인 파란색 (ZOOMIN 로고)
    static let zoominBlueDark  = Color(hex: "#1A5DB5")   // 진한 파란색 (버튼 탭)
    static let zoominBlueLight = Color(hex: "#E8F1FB")   // 연한 파란색 (배경 강조)

    // 상태 컬러 (Status Badge)
    static let statusReceived   = Color(hex: "#9E9E9E")  // 회색   - Received
    static let statusReviewing  = Color(hex: "#2B7FE0")  // 파란색 - Reviewing
    static let statusInProgress = Color(hex: "#FF8C00")  // 주황색 - In Progress
    static let statusCompleted  = Color(hex: "#34C759")  // 초록색 - Completed

    // 위험도 컬러 (Risk Level)
    static let riskLow      = Color(hex: "#34C759")      // 초록
    static let riskMedium   = Color(hex: "#FFD60A")      // 노랑
    static let riskHigh     = Color(hex: "#FF8C00")      // 주황
    static let riskCritical = Color(hex: "#FF3B30")      // 빨강

    // 리워드 컬러
    static let rewardGold   = Color(hex: "#FFD60A")      // 포인트/별
    static let rewardGreen  = Color(hex: "#34C759")      // 배지

    // 배경 / 서피스
    static let surfacePrimary   = Color(hex: "#FFFFFF")
    static let surfaceSecondary = Color(hex: "#F5F7FA")
    static let surfaceTertiary  = Color(hex: "#EEF2F8")

    // 텍스트
    static let textPrimary   = Color(hex: "#1A1A2E")
    static let textSecondary = Color(hex: "#6B7280")
    static let textTertiary  = Color(hex: "#9CA3AF")
}

// Hex 컬러 초기화
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:   Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - 타이포그래피
struct ZOOMINFont {
    // 제목
    static let largeTitle  = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title1      = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title2      = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let title3      = Font.system(size: 16, weight: .semibold, design: .rounded)

    // 본문
    static let body        = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodyBold    = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let caption     = Font.system(size: 13, weight: .regular, design: .rounded)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let micro       = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - 레이아웃 상수
struct ZOOMINLayout {
    static let cornerRadiusSmall:  CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge:  CGFloat = 16
    static let cornerRadiusXL:     CGFloat = 24

    static let paddingSmall:  CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge:  CGFloat = 24

    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Double = 0.08
    static let shadowY: CGFloat = 4
}

// MARK: - Status Badge 컴포넌트 (멤버 전원 공통 사용)
struct ZOOMINStatusBadge: View {
    let status: IssueStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.symbolName)
                .font(.system(size: 11, weight: .semibold))
            Text(status.displayName)
                .font(ZOOMINFont.captionBold)
        }
        .foregroundColor(status.badgeTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.badgeColor.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                .stroke(status.badgeColor.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
    }
}

extension IssueStatus {
    var badgeColor: Color {
        switch self {
        case .received:   return .statusReceived
        case .reviewing:  return .statusReviewing
        case .inProgress: return .statusInProgress
        case .completed:  return .statusCompleted
        }
    }
    var badgeTextColor: Color { badgeColor }
    var symbolName: String {
        switch self {
        case .received:   return "tray.fill"
        case .reviewing:  return "magnifyingglass"
        case .inProgress: return "hammer.fill"
        case .completed:  return "checkmark.circle.fill"
        }
    }
}

// MARK: - Risk Level Badge
struct ZOOMINRiskBadge: View {
    let level: Int  // 1~4: Low, Medium, High, Critical

    var riskLabel: String {
        switch level {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "Critical"
        }
    }
    var riskColor: Color {
        switch level {
        case 1: return .riskLow
        case 2: return .riskMedium
        case 3: return .riskHigh
        default: return .riskCritical
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(riskColor)
                .frame(width: 7, height: 7)
            Text(riskLabel)
                .font(ZOOMINFont.captionBold)
                .foregroundColor(riskColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(riskColor.opacity(0.12))
        .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
    }
}

// MARK: - Category 컬러 & 아이콘 (지도 마커 등)
extension IssueCategory {
    var markerColor: Color {
        switch self {
        case .roadDamage:             return Color(hex: "#FF3B30") // 빨강 - 도로 파손
        case .sidewalkDamage:         return Color(hex: "#FF8C00") // 주황 - 보도 파손
        case .streetlightFailure:     return Color(hex: "#FFD60A") // 노랑 - 가로등
        case .drainageBlocked:        return Color(hex: "#2B7FE0") // 파랑 - 배수
        case .constructionSafetyRisk: return Color(hex: "#AF52DE") // 보라 - 공사 위험
        case .bridgeInfraRisk:        return Color(hex: "#FF6B35") // 진주황 - 교량
        case .other:                  return Color(hex: "#8E8E93") // 회색 - 기타
        }
    }
}

// MARK: - 메인 버튼 스타일
struct ZOOMINPrimaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ZOOMINFont.bodyBold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.zoominBlue, Color.zoominBlueDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .shadow(color: Color.zoominBlue.opacity(0.35),
                    radius: 8, x: 0, y: 4)
    }
}

struct ZOOMINSecondaryButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(ZOOMINFont.bodyBold)
            .foregroundColor(.zoominBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.zoominBlueLight)
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                    .stroke(Color.zoominBlue.opacity(0.3), lineWidth: 1)
            )
    }
}

extension View {
    func zoominPrimaryButton() -> some View {
        self.modifier(ZOOMINPrimaryButton())
    }
    func zoominSecondaryButton() -> some View {
        self.modifier(ZOOMINSecondaryButton())
    }
}

// MARK: - 카드 스타일
struct ZOOMINCard: ViewModifier {
    var padding: CGFloat = ZOOMINLayout.paddingMedium

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surfacePrimary)
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .shadow(color: Color.black.opacity(ZOOMINLayout.shadowOpacity),
                    radius: ZOOMINLayout.shadowRadius,
                    x: 0, y: ZOOMINLayout.shadowY)
    }
}

extension View {
    func zoominCard(padding: CGFloat = ZOOMINLayout.paddingMedium) -> some View {
        self.modifier(ZOOMINCard(padding: padding))
    }
}

// MARK: - PINGO 마스코트 헬퍼 뷰
// 실제 이미지 파일명: pingo_default, pingo_search, pingo_thinking,
//                   pingo_working, pingo_done, pingo_thanks
// Assets에 이미지 추가 후 사용하세요
struct PingoView: View {
    let mood: PingoMood
    var size: CGFloat = 80

    enum PingoMood: String {
        case `default` = "pingo_default"   // 기본
        case search    = "pingo_search"    // 조사 중
        case thinking  = "pingo_thinking"  // 고민 중
        case working   = "pingo_working"   // 처리 중
        case done      = "pingo_done"      // 완료
        case thanks    = "pingo_thanks"    // 감사

        var fallbackSymbol: String {
            switch self {
            case .default:  return "mappin.circle.fill"
            case .search:   return "magnifyingglass.circle.fill"
            case .thinking: return "questionmark.circle.fill"
            case .working:  return "hammer.circle.fill"
            case .done:     return "checkmark.circle.fill"
            case .thanks:   return "heart.circle.fill"
            }
        }
    }

    var body: some View {
        Group {
            if UIImage(named: mood.rawValue) != nil {
                Image(mood.rawValue)
                    .resizable()
                    .scaledToFit()
            } else {
                // 이미지 없을 때 임시 SF Symbol
                Image(systemName: mood.fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.zoominBlue)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 빈 상태 뷰 (PINGO 활용)
struct ZOOMINEmptyStateView: View {
    let mood: PingoView.PingoMood
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            PingoView(mood: mood, size: 100)
            Text(title)
                .font(ZOOMINFont.title2)
                .foregroundColor(.textPrimary)
            Text(message)
                .font(ZOOMINFont.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(ZOOMINLayout.paddingLarge)
    }
}

// MARK: - Priority Score 게이지 바
struct ZOOMINPriorityBar: View {
    let score: Double   // 최대 18점 (5+5+5+3)
    let maxScore: Double = 18

    var fillColor: Color {
        let ratio = score / maxScore
        if ratio >= 0.75 { return .riskCritical }
        if ratio >= 0.55 { return .riskHigh }
        if ratio >= 0.35 { return .riskMedium }
        return .riskLow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Priority Score")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(String(format: "%.1f / 18", score))
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(fillColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [fillColor.opacity(0.7), fillColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(score / maxScore, 1.0)), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 포인트 표시 뷰
struct ZOOMINPointsBadge: View {
    let points: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "p.circle.fill")
                .foregroundColor(.rewardGold)
                .font(.system(size: 14))
            Text("\(points) P")
                .font(ZOOMINFont.captionBold)
                .foregroundColor(.rewardGold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.rewardGold.opacity(0.12))
        .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
    }
}

// MARK: - 네비게이션 바 스타일
struct ZOOMINNavigationStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func zoominNavigationStyle() -> some View {
        self.modifier(ZOOMINNavigationStyle())
    }
}
