// MyIssuesView.swift — 버그 수정본
// 버그 1 수정: Support 버튼 Firestore 연동
// 버그 6 수정: 전체 신고 현황에서 세부 내용으로 이동
// 버그 추가: Comment 기능 추가

import SwiftUI
import Combine

struct MyIssuesView: View {

    @EnvironmentObject var issueStore: IssueStore

    @State private var selectedFilter: IssueStatus? = nil
    @State private var selectedIssue: Issue? = nil
    @State private var showReward: Bool = false

    private var filteredIssues: [Issue] {
        if let filter = selectedFilter {
            return issueStore.myIssues.filter { $0.status == filter }
        }
        return issueStore.myIssues
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()
                if issueStore.myIssues.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: ZOOMINLayout.paddingMedium) {
                            pointsBanner
                            filterBar
                            issueListSection
                        }
                        .padding(.horizontal, ZOOMINLayout.paddingMedium)
                        .padding(.top, ZOOMINLayout.paddingMedium)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("My Issues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReward = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "p.circle.fill").foregroundColor(.rewardGold)
                            Text("\(issueStore.totalRewardPoints) P").font(ZOOMINFont.captionBold).foregroundColor(.rewardGold)
                        }
                    }
                }
            }
            .sheet(item: $selectedIssue) { issue in
                MyIssueDetailSheet(issue: issue).environmentObject(issueStore)
            }
            .sheet(isPresented: $showReward) {
                RewardView().environmentObject(issueStore)
            }
        }
    }

    private var emptyState: some View {
        ZOOMINEmptyStateView(mood: .search, title: "아직 신고한 내역이 없어요", message: "주변의 시설물 문제를 발견하면\n신고 탭에서 제보해 보세요!")
    }

    private var pointsBanner: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("내 총 포인트").font(ZOOMINFont.caption).foregroundColor(.zoominBlueLight.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(issueStore.totalRewardPoints)").font(ZOOMINFont.largeTitle).foregroundColor(.white)
                    Text("P").font(ZOOMINFont.title3).foregroundColor(.white.opacity(0.8))
                }
            }
            Spacer()
            HStack(spacing: 20) {
                BannerStat(label: "전체", value: "\(issueStore.myIssues.count)", color: .white)
                BannerStat(label: "완료", value: "\(issueStore.myIssues.filter { $0.status == .completed }.count)", color: Color(hex: "#34C759"))
                BannerStat(label: "진행 중", value: "\(issueStore.myIssues.filter { $0.status != .completed }.count)", color: Color(hex: "#FFD60A"))
            }
        }
        .padding(ZOOMINLayout.paddingLarge)
        .background(LinearGradient(colors: [Color.zoominBlue, Color.zoominBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(ZOOMINLayout.cornerRadiusXL)
        .shadow(color: Color.zoominBlue.opacity(0.35), radius: 12, x: 0, y: 6)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "전체 (\(issueStore.myIssues.count))", isSelected: selectedFilter == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = nil }
                }
                ForEach(IssueStatus.allCases, id: \.self) { status in
                    let count = issueStore.myIssues.filter { $0.status == status }.count
                    FilterPill(label: "\(status.displayName) (\(count))", isSelected: selectedFilter == status, accentColor: status.badgeColor) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedFilter = (selectedFilter == status) ? nil : status }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var issueListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("신고 내역").font(ZOOMINFont.title3).foregroundColor(.textPrimary)
                Spacer()
                Text("\(filteredIssues.count)건").font(ZOOMINFont.caption).foregroundColor(.textTertiary)
            }
            if filteredIssues.isEmpty {
                ZOOMINEmptyStateView(mood: .done, title: "해당 신고가 없습니다", message: "선택한 상태의 신고가 없어요")
                    .frame(maxWidth: .infinity).zoominCard()
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredIssues) { issue in
                        MyIssueCard(issue: issue) {
                            selectedIssue = issue
                        }
                    }
                }
            }
        }
    }
}

private struct BannerStat: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(ZOOMINFont.title2).foregroundColor(color)
            Text(label).font(ZOOMINFont.micro).foregroundColor(.white.opacity(0.7))
        }
    }
}

private struct FilterPill: View {
    let label: String; let isSelected: Bool; var accentColor: Color = .zoominBlue; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label).font(ZOOMINFont.captionBold)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? accentColor : Color.surfacePrimary)
                .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
                .overlay(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall).stroke(isSelected ? accentColor : Color.textTertiary.opacity(0.4), lineWidth: 1))
        }
    }
}

struct MyIssueCard: View {
    let issue: Issue; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                if issue.status == .completed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 11))
                        Text("처리 완료되었습니다").font(ZOOMINFont.micro).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ZOOMINLayout.paddingMedium).padding(.vertical, 7)
                    .background(Color.statusCompleted)
                }
                HStack(alignment: .top, spacing: 12) {
                    photoOrIcon
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(issue.title).font(ZOOMINFont.bodyBold).foregroundColor(.textPrimary).lineLimit(2).multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            ZOOMINStatusBadge(status: issue.status)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: issue.category.symbolName).font(.system(size: 11)).foregroundColor(issue.category.markerColor)
                            Text(issue.category.displayName).font(ZOOMINFont.caption).foregroundColor(.textSecondary)
                        }
                        HStack(spacing: 8) {
                            ZOOMINPointsBadge(points: issue.rewardPoints)
                            HStack(spacing: 3) {
                                Image(systemName: "hand.thumbsup.fill").font(.system(size: 11)).foregroundColor(.zoominBlue.opacity(0.7))
                                Text("지지 \(issue.supportCount)").font(ZOOMINFont.caption).foregroundColor(.textSecondary)
                            }
                            Spacer()
                            Text(issue.reportDate.formatted(.dateTime.month().day())).font(ZOOMINFont.micro).foregroundColor(.textTertiary)
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.textTertiary)
                        }
                        if let summary = issue.completionSummary, !summary.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "doc.text.fill").font(.system(size: 11)).foregroundColor(.statusCompleted)
                                Text(summary).font(ZOOMINFont.caption).foregroundColor(.textSecondary).lineLimit(2)
                            }
                            .padding(ZOOMINLayout.paddingSmall)
                            .background(Color.statusCompleted.opacity(0.07))
                            .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
                        }
                    }
                }
                .padding(ZOOMINLayout.paddingMedium)
            }
        }
        .buttonStyle(.plain)
        .background(Color.surfacePrimary)
        .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
        .shadow(color: issue.status == .completed ? Color.statusCompleted.opacity(0.12) : Color.black.opacity(ZOOMINLayout.shadowOpacity), radius: ZOOMINLayout.shadowRadius, x: 0, y: ZOOMINLayout.shadowY)
        .overlay(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge).stroke(issue.status == .completed ? Color.statusCompleted.opacity(0.35) : Color.clear, lineWidth: 1.5))
    }

    @ViewBuilder
    private var photoOrIcon: some View {
        Group {
            if let data = issue.photoData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                ZStack {
                    Color(issue.category.markerColor).opacity(0.12)
                    Image(systemName: issue.category.symbolName).font(.system(size: 20, weight: .semibold)).foregroundColor(issue.category.markerColor)
                }
            }
        }
        .frame(width: 68, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
    }
}

// MARK: - 상세 시트 (버그 1, 6 수정: Support 버튼 연동 + 코멘트 기능)

struct MyIssueDetailSheet: View {

    @EnvironmentObject var issueStore: IssueStore
    @Environment(\.dismiss) private var dismiss

    let issue: Issue
    @State private var commentText: String = ""
    @State private var comments: [String] = []
    @State private var didSupport: Bool = false

    private var currentIssue: Issue {
        issueStore.issues.first { $0.id == issue.id } ?? issue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: ZOOMINLayout.paddingMedium) {
                        photoSection
                        infoCard
                        // 버그 1 수정: Support 버튼 Firestore 연동
                        supportCard
                        priorityCard
                        // 버그 추가: 코멘트 기능
                        commentCard
                        if let summary = currentIssue.completionSummary, !summary.isEmpty {
                            completionCard(summary: summary)
                        }
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("신고 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }.foregroundColor(.zoominBlue)
                }
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let data = currentIssue.photoData, let uiImg = UIImage(data: data) {
            Image(uiImage: uiImg).resizable().scaledToFill()
                .frame(maxWidth: .infinity).frame(height: 220).clipped()
                .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(currentIssue.title).font(ZOOMINFont.title2).foregroundColor(.textPrimary)
                Spacer()
                ZOOMINStatusBadge(status: currentIssue.status)
            }
            HStack(spacing: 8) {
                Image(systemName: currentIssue.category.symbolName).font(.system(size: 13)).foregroundColor(currentIssue.category.markerColor)
                Text(currentIssue.category.displayName).font(ZOOMINFont.captionBold).foregroundColor(.textSecondary)
                Spacer()
                ZOOMINPointsBadge(points: currentIssue.rewardPoints)
            }
            if !currentIssue.description.isEmpty {
                Text(currentIssue.description).font(ZOOMINFont.body).foregroundColor(.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Label(currentIssue.reportDate.formatted(.dateTime.year().month().day()), systemImage: "calendar").font(ZOOMINFont.caption).foregroundColor(.textTertiary)
                Spacer()
            }
        }
        .zoominCard()
    }

    // 버그 1 수정: Support 버튼
    private var supportCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("이 신고를 지지하나요?").font(ZOOMINFont.bodyBold).foregroundColor(.textPrimary)
                Text("지지가 많을수록 우선 처리됩니다").font(ZOOMINFont.caption).foregroundColor(.textSecondary)
            }
            Spacer()
            Button {
                if !didSupport {
                    issueStore.supportIssue(issueID: currentIssue.id)
                    didSupport = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: didSupport ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.system(size: 16))
                    Text("\(currentIssue.supportCount)")
                        .font(ZOOMINFont.bodyBold)
                }
                .foregroundColor(didSupport ? .white : .zoominBlue)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(didSupport ? Color.zoominBlue : Color.zoominBlueLight)
                .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            }
            .disabled(didSupport)
        }
        .zoominCard()
    }

    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("우선순위 분석").font(ZOOMINFont.title3).foregroundColor(.textPrimary)
            ZOOMINPriorityBar(score: Double(currentIssue.priorityScore))
            HStack(spacing: 0) {
                PriorityFactorCell(label: "안전위험", value: currentIssue.safetyRisk, color: .riskCritical)
                Divider().frame(height: 36)
                PriorityFactorCell(label: "긴급도", value: currentIssue.urgency, color: .riskHigh)
                Divider().frame(height: 36)
                PriorityFactorCell(label: "공공영향", value: currentIssue.publicImpact, color: .riskMedium)
                Divider().frame(height: 36)
                PriorityFactorCell(label: "지지점수", value: currentIssue.supportScore, color: .zoominBlue)
            }
            .padding(.vertical, 8)
            .background(Color.surfaceSecondary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
        }
        .zoominCard()
    }

    // 코멘트 기능
    private var commentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("코멘트").font(ZOOMINFont.title3).foregroundColor(.textPrimary)

            if comments.isEmpty {
                Text("아직 코멘트가 없어요").font(ZOOMINFont.caption).foregroundColor(.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comments, id: \.self) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill").font(.system(size: 24)).foregroundColor(.textTertiary)
                            Text(comment).font(ZOOMINFont.body).foregroundColor(.textPrimary)
                                .padding(ZOOMINLayout.paddingSmall)
                                .background(Color.surfaceSecondary)
                                .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("코멘트 입력...", text: $commentText)
                    .font(ZOOMINFont.body)
                    .padding(ZOOMINLayout.paddingSmall)
                    .background(Color.surfaceSecondary)
                    .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
                Button {
                    let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        comments.append(trimmed)
                        commentText = ""
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(commentText.isEmpty ? Color.textTertiary : Color.zoominBlue)
                        .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
                }
                .disabled(commentText.isEmpty)
            }
        }
        .zoominCard()
    }

    private func completionCard(summary: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.statusCompleted)
                Text("처리 완료 보고서").font(ZOOMINFont.title3).foregroundColor(.textPrimary)
            }
            Text(summary).font(ZOOMINFont.body).foregroundColor(.textSecondary).fixedSize(horizontal: false, vertical: true)
            if let date = currentIssue.completionDate {
                Label(date.formatted(.dateTime.year().month().day()), systemImage: "calendar.badge.checkmark")
                    .font(ZOOMINFont.caption).foregroundColor(.textTertiary)
            }
        }
        .zoominCard()
        .overlay(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge).stroke(Color.statusCompleted.opacity(0.35), lineWidth: 1.5))
    }
}

private struct PriorityFactorCell: View {
    let label: String; let value: Int; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)").font(ZOOMINFont.title2).foregroundColor(color)
            Text(label).font(ZOOMINFont.micro).foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MyIssuesView().environmentObject(IssueStore())
}
