import SwiftUI

// ============================================================
//  ZOOMINStyle.swift
//  Shared Design System — All team members use this file
//  Based on PINGO mascot + design guide
// ============================================================

// MARK: - Brand Colors
extension Color {
    // Main brand
    static let zoominBlue      = Color(hex: "#2B7FE0")   // Main blue (ZOOMIN logo)
    static let zoominBlueDark  = Color(hex: "#1A5DB5")   // Dark blue (button tap)
    static let zoominBlueLight = Color(hex: "#E8F1FB")   // Light blue (background accent)

    // Status colors (Status Badge)
    static let statusReceived   = Color(hex: "#9E9E9E")  // Gray   - Received
    static let statusReviewing  = Color(hex: "#2B7FE0")  // Blue   - Reviewing
    static let statusInProgress = Color(hex: "#FF8C00")  // Orange - In Progress
    static let statusCompleted  = Color(hex: "#34C759")  // Green  - Completed

    // Risk level colors
    static let riskLow      = Color(hex: "#34C759")      // Green
    static let riskMedium   = Color(hex: "#FFD60A")      // Yellow
    static let riskHigh     = Color(hex: "#FF8C00")      // Orange
    static let riskCritical = Color(hex: "#FF3B30")      // Red

    // Reward colors
    static let rewardGold   = Color(hex: "#FFD60A")      // Points / star
    static let rewardGreen  = Color(hex: "#34C759")      // Badge

    // Background / Surface
    static let surfacePrimary   = Color(hex: "#FFFFFF")
    static let surfaceSecondary = Color(hex: "#F5F7FA")
    static let surfaceTertiary  = Color(hex: "#EEF2F8")

    // Text
    static let textPrimary   = Color(hex: "#1A1A2E")
    static let textSecondary = Color(hex: "#6B7280")
    static let textTertiary  = Color(hex: "#9CA3AF")
}

// Hex color initializer
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

// MARK: - Typography
struct ZOOMINFont {
    // Headings
    static let largeTitle  = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title1      = Font.system(size: 22, weight: .bold, design: .rounded)
    static let title2      = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let title3      = Font.system(size: 16, weight: .semibold, design: .rounded)

    // Body
    static let body        = Font.system(size: 15, weight: .regular, design: .rounded)
    static let bodyBold    = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let caption     = Font.system(size: 13, weight: .regular, design: .rounded)
    static let captionBold = Font.system(size: 13, weight: .semibold, design: .rounded)
    static let micro       = Font.system(size: 11, weight: .medium, design: .rounded)
}

// MARK: - Layout Constants
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

// MARK: - Status Badge Component (shared by all members)
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

// MARK: - Category Color & Icon (map markers etc.)
extension IssueCategory {
    var markerColor: Color {
        switch self {
        case .roadDamage:             return Color(hex: "#FF3B30") // Red    - Road Damage
        case .sidewalkDamage:         return Color(hex: "#FF8C00") // Orange - Sidewalk Damage
        case .streetlightFailure:     return Color(hex: "#FFD60A") // Yellow - Streetlight
        case .drainageBlocked:        return Color(hex: "#2B7FE0") // Blue   - Drainage
        case .constructionSafetyRisk: return Color(hex: "#AF52DE") // Purple - Construction Risk
        case .bridgeInfraRisk:        return Color(hex: "#FF6B35") // Dark Orange - Bridge
        case .other:                  return Color(hex: "#8E8E93") // Gray   - Other
        }
    }
}

// MARK: - Primary Button Style
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

// MARK: - Card Style
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

// MARK: - PINGO Mascot Helper View
// Image filenames: pingo_default, pingo_search, pingo_thinking,
//                 pingo_working, pingo_done, pingo_thanks
// Add images to Assets before use
struct PingoView: View {
    let mood: PingoMood
    var size: CGFloat = 80

    enum PingoMood: String {
        case `default` = "pingo_default"
        case search    = "pingo_search"
        case thinking  = "pingo_thinking"
        case working   = "pingo_working"
        case done      = "pingo_done"
        case thanks    = "pingo_thanks"

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
                Image(systemName: mood.fallbackSymbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.zoominBlue)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty State View (using PINGO)
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

// MARK: - Priority Score Gauge Bar
struct ZOOMINPriorityBar: View {
    let score: Double   // Max 18 points (5+5+5+3)
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

// MARK: - Points Badge
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

// MARK: - Navigation Bar Style
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
