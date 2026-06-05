// PriorityScoreView.swift
// ZOOMIN — Member 3 담당
// Role: Priority Score card showing total score and 4 sub-factors
//
// Priority Score formula:
// Total = Safety Risk + Urgency + Public Impact + Support Score
// Max = 5 + 5 + 5 + 3 = 18
// Support Score is capped at 3 to prevent manipulation (see Issue.swift)

import SwiftUI

struct PriorityScoreView: View {

    let issue: Issue

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Section header + priority level badge
            HStack {
                Label("Priority Score", systemImage: "chart.bar.fill")
                    .font(ZOOMINFont.title2)
                    .foregroundColor(Color.textPrimary)
                Spacer()
                priorityLevelBadge
            }

            // Main score bar (ZOOMINPriorityBar takes Double)
            ZOOMINPriorityBar(score: Double(issue.priorityScore))

            // Total score
            HStack {
                Text("Total")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(Color.textSecondary)
                Spacer()
                Text("\(issue.priorityScore) / 18")
                    .font(ZOOMINFont.bodyBold)
                    .foregroundColor(Color.zoominBlue)
            }

            Divider()

            // 4 sub-factors
            // Safety Risk: how dangerous the issue is (1~5)
            scoreRow(
                icon: "exclamationmark.shield.fill",
                iconColor: Color.riskCritical,
                label: "Safety",
                value: issue.safetyRisk,
                maxValue: 5,
                note: "How dangerous this issue is"
            )

            // Urgency: how quickly it should be fixed (1~5)
            scoreRow(
                icon: "clock.fill",
                iconColor: Color.riskHigh,
                label: "Urgency",
                value: issue.urgency,
                maxValue: 5,
                note: "How quickly it should be fixed"
            )

            // Public Impact: how many people are affected (1~5)
            scoreRow(
                icon: "person.3.fill",
                iconColor: Color.zoominBlue,
                label: "Impact",
                value: issue.publicImpact,
                maxValue: 5,
                note: "How many people are affected"
            )

            // Support Score: community support, capped at 3
            // 0-5 supports = 0pts, 6-10 = 1pt, 11-20 = 2pts, 21+ = 3pts
            scoreRow(
                icon: "heart.fill",
                iconColor: Color.riskMedium,
                label: "Support",
                value: issue.supportScore,
                maxValue: 3,
                note: "Community support (capped at 3)"
            )

            // Formula explanation note
            formulaNote
        }
        .zoominCard()
    }

    // MARK: - Priority level badge
    // issue.priorityLevel returns PriorityLevel enum (.high / .medium / .low)
    private var priorityLevelBadge: some View {
        let (label, color): (String, Color) = {
            switch issue.priorityLevel {
            case .high:   return ("High",   Color.riskCritical)
            case .medium: return ("Medium", Color.riskHigh)
            case .low:    return ("Low",    Color.riskLow)
            }
        }()
        return Text(label)
            .font(ZOOMINFont.captionBold)
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
    }

    // MARK: - Score row with mini progress bar
    private func scoreRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: Int,
        maxValue: Int,
        note: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
                    .frame(width: 18)
                Text(label)
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(Color.textPrimary)
                Spacer()
                Text("\(value) / \(maxValue)")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(iconColor)
            }

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(iconColor.opacity(0.8))
                        .frame(
                            width: geo.size.width * CGFloat(value) / CGFloat(maxValue),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            Text(note)
                .font(.caption2)
                .foregroundColor(Color.textTertiary)
        }
    }

    // MARK: - Formula note
    private var formulaNote: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("How is priority calculated?", systemImage: "function")
                .font(ZOOMINFont.captionBold)
                .foregroundColor(Color.textSecondary)
            Text("Score = Safety + Urgency + Impact + Support")
                .font(.caption2)
                .foregroundColor(Color.textTertiary)
            Text("Support is capped at 3 (max 21 supports) to prevent manipulation.")
                .font(.caption2)
                .foregroundColor(Color.textTertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceSecondary)
        .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
    }
}

#Preview {
    PriorityScoreView(issue: IssueStore().issues[0])
        .padding()
        .background(Color.surfaceSecondary)
}
