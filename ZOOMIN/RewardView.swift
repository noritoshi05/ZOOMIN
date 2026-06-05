// RewardView.swift
// ZOOMIN — Member 4
// Role: Points status / Coupon reward list / How to earn points

import SwiftUI

struct RewardView: View {

    @EnvironmentObject var issueStore: IssueStore
    @Environment(\.dismiss) private var dismiss

    // Whether coupons are redeemable (based on total points)
    private var totalPoints: Int { issueStore.totalRewardPoints }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ZOOMINLayout.paddingMedium) {

                        // 1. Points hero card
                        pointsHeroCard

                        // 2. Coupon reward list
                        couponSection

                        // 3. How to earn points
                        earnGuideSection

                        // 4. My points history
                        pointsHistorySection
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.zoominBlue)
                }
            }
        }
    }

    // MARK: - 1. Points Hero Card

    private var pointsHeroCard: some View {
        VStack(spacing: 16) {

            // Coin icon
            ZStack {
                Circle()
                    .fill(Color.rewardGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "p.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.rewardGold)
            }

            // Points value
            VStack(spacing: 4) {
                Text("My Points")
                    .font(ZOOMINFont.caption)
                    .foregroundColor(.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(totalPoints)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Text("P")
                        .font(ZOOMINFont.title2)
                        .foregroundColor(.textSecondary)
                }
            }

            // Progress bar to next coupon
            nextCouponProgress

            // Report count summary
            HStack(spacing: 0) {
                PointStatCell(label: "Total Reports",
                              value: "\(issueStore.myIssues.count)",
                              icon: "flag.fill",
                              color: .zoominBlue)
                Divider().frame(height: 36)
                PointStatCell(label: "Completed",
                              value: "\(issueStore.myIssues.filter { $0.status == .completed }.count)",
                              icon: "checkmark.circle.fill",
                              color: .statusCompleted)
                Divider().frame(height: 36)
                PointStatCell(label: "Times Supported",
                              value: "\(issueStore.myIssues.reduce(0) { $0 + $1.supportCount })",
                              icon: "hand.thumbsup.fill",
                              color: .riskHigh)
            }
            .padding(.vertical, 8)
            .background(Color.surfaceSecondary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
        }
        .zoominCard()
    }

    // Progress bar to next coupon
    private var nextCouponProgress: some View {
        let tiers = [100, 200, 300]
        let nextTier = tiers.first { $0 > totalPoints } ?? 300
        let prevTier = tiers.last { $0 <= totalPoints } ?? 0
        let progress = totalPoints >= 300
            ? 1.0
            : Double(totalPoints - prevTier) / Double(nextTier - prevTier)

        return VStack(spacing: 6) {
            HStack {
                Text(totalPoints >= 300 ? "All rewards unlocked!" : "Until next coupon")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                Spacer()
                if totalPoints < 300 {
                    Text("\(nextTier - totalPoints)P left")
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(.rewardGold)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surfaceTertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.rewardGold.opacity(0.7), Color.rewardGold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(progress, 1.0)), height: 8)
                }
            }
            .frame(height: 8)

            // Stage markers
            HStack {
                Text("0")
                Spacer()
                Text("100")
                Spacer()
                Text("200")
                Spacer()
                Text("300")
            }
            .font(ZOOMINFont.micro)
            .foregroundColor(.textTertiary)
        }
    }

    // MARK: - 2. Coupon Reward List

    private var couponSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coupon Rewards")
                    .font(ZOOMINFont.title3)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("Redeemable with points")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }

            VStack(spacing: 10) {
                CouponCard(
                    icon: "cup.and.saucer.fill",
                    title: "Local Cafe Coupon",
                    subtitle: "1 drink at a local partner cafe",
                    requiredPoints: 100,
                    currentPoints: totalPoints,
                    color: Color(hex: "#A0522D")
                )
                CouponCard(
                    icon: "storefront.fill",
                    title: "Local Market Coupon",
                    subtitle: "Discount at local market partners",
                    requiredPoints: 200,
                    currentPoints: totalPoints,
                    color: Color(hex: "#2E8B57")
                )
                CouponCard(
                    icon: "building.2.fill",
                    title: "Public Facility Discount",
                    subtitle: "Discount at pools, gyms, and more",
                    requiredPoints: 300,
                    currentPoints: totalPoints,
                    color: .zoominBlue
                )
            }

            // Info note
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
                Text("To prevent false reports, major rewards require admin review. Submitting a report earns a small amount of points. Points accumulate as reports are processed.")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .zoominCard()
    }

    // MARK: - 3. How to Earn Points

    private var earnGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Earn Points")
                .font(ZOOMINFont.title3)
                .foregroundColor(.textPrimary)

            VStack(spacing: 0) {
                EarnRow(icon: "flag.fill",
                        label: "Submit Report",
                        points: "+10 P",
                        color: .zoominBlue,
                        isLast: false)
                EarnRow(icon: "camera.fill",
                        label: "Photo Attachment Bonus",
                        points: "+5 P",
                        color: .zoominBlue,
                        isLast: false)
                EarnRow(icon: "hand.thumbsup.fill",
                        label: "Support Other Reports",
                        points: "+2 P",
                        color: .riskMedium,
                        isLast: false)
                EarnRow(icon: "magnifyingglass",
                        label: "Report Reviewed",
                        points: "+10 P",
                        color: .statusReviewing,
                        isLast: false)
                EarnRow(icon: "checkmark.circle.fill",
                        label: "Report Completed",
                        points: "+30 P",
                        color: .statusCompleted,
                        isLast: false)
                EarnRow(icon: "doc.text.fill",
                        label: "Completion Feedback Received",
                        points: "+5 P",
                        color: .statusCompleted,
                        isLast: true)
            }
            .background(Color.surfaceSecondary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
        }
        .zoominCard()
    }

    // MARK: - 4. Points History

    private var pointsHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points by Report")
                .font(ZOOMINFont.title3)
                .foregroundColor(.textPrimary)

            if issueStore.myIssues.isEmpty {
                Text("No reports yet")
                    .font(ZOOMINFont.body)
                    .foregroundColor(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ZOOMINLayout.paddingLarge)
            } else {
                VStack(spacing: 8) {
                    ForEach(issueStore.myIssues.sorted { $0.rewardPoints > $1.rewardPoints }) { issue in
                        PointsHistoryRow(issue: issue)
                    }
                }
            }
        }
        .zoominCard()
    }
}

// MARK: - Points Stat Cell

private struct PointStatCell: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            Text(value)
                .font(ZOOMINFont.bodyBold)
                .foregroundColor(.textPrimary)
            Text(label)
                .font(ZOOMINFont.micro)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Coupon Card

private struct CouponCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let requiredPoints: Int
    let currentPoints: Int
    let color: Color

    private var isUnlocked: Bool { currentPoints >= requiredPoints }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .fill(isUnlocked ? color.opacity(0.15) : Color.surfaceTertiary)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isUnlocked ? color : .textTertiary)
            }

            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(ZOOMINFont.bodyBold)
                    .foregroundColor(isUnlocked ? .textPrimary : .textTertiary)
                Text(subtitle)
                    .font(ZOOMINFont.caption)
                    .foregroundColor(isUnlocked ? .textSecondary : .textTertiary)
            }

            Spacer()

            // Points / Lock
            VStack(alignment: .trailing, spacing: 4) {
                if isUnlocked {
                    Text("Redeemable")
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(.statusCompleted)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.statusCompleted)
                        .font(.system(size: 18))
                } else {
                    Text("\(requiredPoints) P")
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(.rewardGold)
                    Image(systemName: "lock.fill")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(ZOOMINLayout.paddingMedium)
        .background(
            isUnlocked
                ? color.opacity(0.06)
                : Color.surfacePrimary
        )
        .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                .stroke(
                    isUnlocked ? color.opacity(0.3) : Color.textTertiary.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Earn Guide Row

private struct EarnRow: View {
    let icon: String
    let label: String
    let points: String
    let color: Color
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(label)
                    .font(ZOOMINFont.body)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text(points)
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.rewardGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rewardGold.opacity(0.12))
                    .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
            }
            .padding(.horizontal, ZOOMINLayout.paddingMedium)
            .padding(.vertical, 12)

            if !isLast {
                Divider()
                    .padding(.leading, ZOOMINLayout.paddingMedium + 24 + 12)
            }
        }
    }
}

// MARK: - Points History Row

private struct PointsHistoryRow: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 10) {
            // Category icon
            ZStack {
                Color(issue.category.markerColor).opacity(0.10)
                Image(systemName: issue.category.symbolName)
                    .font(.system(size: 14))
                    .foregroundColor(issue.category.markerColor)
            }
            .frame(width: 36, height: 36)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))

            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)
                ZOOMINStatusBadge(status: issue.status)
            }

            Spacer()

            ZOOMINPointsBadge(points: issue.rewardPoints)
        }
        .padding(ZOOMINLayout.paddingSmall)
        .background(Color.surfaceSecondary)
        .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
    }
}
