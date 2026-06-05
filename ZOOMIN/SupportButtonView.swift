// SupportButtonView.swift
// ZOOMIN — Member 3 담당
// Role: Support Button with heart icon and support count display

import SwiftUI

struct SupportButtonView: View {

    let issue: Issue
    @EnvironmentObject var issueStore: IssueStore

    // Tracks if user already supported in this session
    @State private var hasSupported: Bool = false
    @State private var isAnimating: Bool = false

    var body: some View {
        HStack(spacing: 12) {

            // Heart button + count
            Button {
                guard !hasSupported else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isAnimating = true
                    hasSupported = true
                }
                // Calls IssueStore.supportIssue — increments supportCount by 1
                // Priority score updates automatically via computed property in Issue.swift
                issueStore.supportIssue(issueID: issue.id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    isAnimating = false
                }
            } label: {
                HStack(spacing: 10) {
                    // Heart icon: red (riskCritical) after support, grey before
                    Image(systemName: hasSupported ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(hasSupported ? Color.riskCritical : Color.textTertiary)
                        .scaleEffect(isAnimating ? 1.4 : 1.0)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(issue.supportCount)")
                            .font(ZOOMINFont.bodyBold)
                            .foregroundColor(Color.textPrimary)
                        Text(hasSupported ? "You supported this" : "Support this issue")
                            .font(ZOOMINFont.caption)
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                        .fill(hasSupported ? Color.riskCritical.opacity(0.08) : Color.surfaceSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                        .stroke(
                            hasSupported ? Color.riskCritical.opacity(0.3) : Color.clear,
                            lineWidth: 1.5
                        )
                )
            }
            .disabled(hasSupported)

            // Info chip explaining support score cap
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                    .foregroundColor(Color.textTertiary)
                Text("Score\ncapped at 3")
                    .font(.caption2)
                    .foregroundColor(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.surfaceSecondary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
        }
        .zoominCard()
    }
}
