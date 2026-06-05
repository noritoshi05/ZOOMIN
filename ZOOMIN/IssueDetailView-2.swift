// IssueDetailView.swift
// ZOOMIN — Member 3 담당
// Role: Issue Detail screen
//
// ⚠️ 통합 주의사항:
//   - MapView.swift 안의 임시 IssueDetailView struct 전체를 삭제하세요.
//   - SupportButtonView → SupportButtonView.swift
//   - PriorityScoreView → PriorityScoreView.swift

import SwiftUI

// MARK: - IssueDetailView

struct IssueDetailView: View {

    let issue: Issue
    @EnvironmentObject var issueStore: IssueStore

    @State private var showShareSheet = false

    // Always read live data from store so supportCount updates in real time
    private var liveIssue: Issue {
        issueStore.issues.first(where: { $0.id == issue.id }) ?? issue
    }

    var body: some View {
        ZStack {
            Color.surfaceSecondary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // 1. Top photo area (full width, 240pt tall)
                    photoHeader

                    // 2. Content cards
                    VStack(spacing: 12) {
                        infoCard
                        SupportButtonView(issue: liveIssue)
                            .environmentObject(issueStore)
                        PriorityScoreView(issue: liveIssue)
                        BottomTabSection(issue: liveIssue)
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Check this issue on ZOOMIN: \(liveIssue.title)"])
        }
    }

    // MARK: - Photo header (240pt)

    private var photoHeader: some View {
        ZStack(alignment: .top) {

            // Photo or fallback icon
            Group {
                if let uiImg = liveIssue.uiImage {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                } else if let name = liveIssue.imageName, !name.isEmpty {
                    Image(name)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        liveIssue.category.markerColor.opacity(0.10)
                        Image(systemName: liveIssue.category.symbolName)
                            .font(.system(size: 72, weight: .light))
                            .foregroundColor(liveIssue.category.markerColor.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .clipped()

            // Top-left category badge + top-right share button
            HStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: liveIssue.category.symbolName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(liveIssue.category.displayName)
                        .font(ZOOMINFont.captionBold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(liveIssue.category.markerColor)
                .clipShape(Capsule())

                Spacer()

                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, ZOOMINLayout.paddingMedium)
            .padding(.top, 14)
        }
    }

    // MARK: - Info card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Title
            Text(liveIssue.title)
                .font(ZOOMINFont.title2)
                .foregroundColor(Color.textPrimary)

            // Location + date
            HStack(spacing: 16) {
                Label("Near your area", systemImage: "mappin.circle.fill")
                    .font(ZOOMINFont.caption)
                    .foregroundColor(Color.textSecondary)
                Label(
                    liveIssue.reportDate.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                .font(ZOOMINFont.caption)
                .foregroundColor(Color.textSecondary)
            }

            Divider()

            // Status badge + Risk badge side by side
            HStack(spacing: 8) {
                ZOOMINStatusBadge(status: liveIssue.status)
                ZOOMINRiskBadge(level: liveIssue.safetyRisk)
                Spacer()
            }

            // Description
            if !liveIssue.description.isEmpty {
                Text(liveIssue.description)
                    .font(ZOOMINFont.body)
                    .foregroundColor(Color.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Completion summary (only shown when status is .completed)
            if liveIssue.status == .completed,
               let summary = liveIssue.completionSummary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Completion Report", systemImage: "checkmark.seal.fill")
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(Color.zoominBlue)
                    Text(summary)
                        .font(ZOOMINFont.caption)
                        .foregroundColor(Color.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.zoominBlue.opacity(0.06))
                .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zoominCard()
    }
}

// MARK: - Bottom Tab Section (Details / Updates / Comments)

struct BottomTabSection: View {

    let issue: Issue
    @State private var selectedTab: Int = 0
    private let tabs = ["Details", "Updates", "Comments"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Tab header row
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { idx, tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = idx
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab)
                                .font(ZOOMINFont.captionBold)
                                .foregroundColor(
                                    selectedTab == idx ? Color.zoominBlue : Color.textTertiary
                                )
                            // Selected tab: 2pt blue underline
                            Rectangle()
                                .fill(selectedTab == idx ? Color.zoominBlue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Divider().padding(.top, 4)

            Group {
                switch selectedTab {
                case 0: detailsTab
                case 1: updatesTab
                default: commentsTab
                }
            }
            .padding(.top, 12)
        }
        .zoominCard()
    }

    // MARK: Details tab
    private var detailsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            detailRow(icon: "person.fill",                  label: "Reporter",  value: "Anonymous Resident")
            detailRow(icon: "tag.fill",                     label: "Category",  value: issue.category.displayName)
            detailRow(icon: "exclamationmark.triangle.fill", label: "Safety",   value: riskLabel(issue.safetyRisk))
            detailRow(icon: "clock.fill",                   label: "Urgency",   value: urgencyLabel(issue.urgency))
            detailRow(icon: "person.3.fill",                label: "Impact",    value: impactLabel(issue.publicImpact))
            detailRow(icon: "calendar",                     label: "Reported",
                      value: issue.reportDate.formatted(date: .long, time: .omitted))
            if let completion = issue.completionDate {
                detailRow(icon: "checkmark.seal.fill", label: "Completed",
                          value: completion.formatted(date: .long, time: .omitted))
            }
            detailRow(icon: "p.circle.fill", label: "Points", value: "\(issue.rewardPoints) P")
        }
    }

    // MARK: Updates tab (timeline)
    private var updatesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(IssueStatus.allCases, id: \.self) { st in
                let reached = statusOrder(st) <= statusOrder(issue.status)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(st.badgeColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        if reached {
                            Circle()
                                .fill(st.badgeColor)
                                .frame(width: 20, height: 20)
                            Image(systemName: st.symbolName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(st.displayName)
                            .font(ZOOMINFont.captionBold)
                            .foregroundColor(reached ? st.badgeColor : Color.textTertiary)
                        if issue.status == st {
                            Text("Current status")
                                .font(ZOOMINFont.micro)
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: Comments tab (placeholder)
    private var commentsTab: some View {
        ZOOMINEmptyStateView(
            mood: .thinking,
            title: "No Comments Yet",
            message: "Be the first to comment on this issue."
        )
    }

    // MARK: Helpers
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Color.zoominBlue)
                .frame(width: 18)
            Text(label)
                .font(ZOOMINFont.caption)
                .foregroundColor(Color.textSecondary)
                .frame(width: 75, alignment: .leading)
            Text(value)
                .font(ZOOMINFont.captionBold)
                .foregroundColor(Color.textPrimary)
        }
    }

    private func statusOrder(_ s: IssueStatus) -> Int {
        switch s {
        case .received:   return 0
        case .reviewing:  return 1
        case .inProgress: return 2
        case .completed:  return 3
        }
    }

    private func riskLabel(_ v: Int) -> String {
        switch v {
        case 1: return "1 – Low"
        case 2: return "2 – Minor"
        case 3: return "3 – Medium"
        case 4: return "4 – High"
        default: return "5 – Critical"
        }
    }

    private func urgencyLabel(_ v: Int) -> String {
        switch v {
        case 1: return "1 – Not urgent"
        case 2: return "2 – Low"
        case 3: return "3 – Moderate"
        case 4: return "4 – Urgent"
        default: return "5 – Immediate"
        }
    }

    private func impactLabel(_ v: Int) -> String {
        switch v {
        case 1: return "1 – Minimal"
        case 2: return "2 – Some people"
        case 3: return "3 – Neighborhood"
        case 4: return "4 – Many people"
        default: return "5 – Widespread"
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Previews

#Preview("IssueDetailView") {
    NavigationStack {
        IssueDetailView(issue: IssueStore().issues[0])
            .environmentObject(IssueStore())
    }
}
