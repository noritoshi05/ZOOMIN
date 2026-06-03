// AdminDashboardView.swift
// ZOOMIN — Member 4 담당
// 역할: 관리자 대시보드 / 우선순위 정렬 / 상태 관리 / 완료 보고서
// 디자인: ZOOMINStyle.swift 완전 적용

import SwiftUI

// MARK: - AdminDashboardView (메인 진입점)

struct AdminDashboardView: View {

    @EnvironmentObject var issueStore: IssueStore

    @State private var selectedFilter: IssueStatus? = nil
    @State private var selectedIssue: Issue? = nil
    @State private var showStatusSheet: Bool = false
    @State private var showCompletionSheet: Bool = false

    // 필터 적용된 이슈 목록 (항상 우선순위 내림차순)
    private var filteredIssues: [Issue] {
        if let filter = selectedFilter {
            return issueStore.sortedByPriority.filter { $0.status == filter }
        }
        return issueStore.sortedByPriority
    }

    // 상태별 건수 요약
    private var receivedCount:   Int { issueStore.issues.filter { $0.status == .received   }.count }
    private var reviewingCount:  Int { issueStore.issues.filter { $0.status == .reviewing  }.count }
    private var inProgressCount: Int { issueStore.issues.filter { $0.status == .inProgress }.count }
    private var completedCount:  Int { issueStore.issues.filter { $0.status == .completed  }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ZOOMINLayout.paddingMedium) {

                        // 1. 상단 요약 카드
                        summarySection

                        // 2. 상태 필터 탭
                        filterBar

                        // 3. 이슈 목록
                        issueListSection
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            // 상태 변경 시트
            .sheet(item: $selectedIssue) { issue in
                if showCompletionSheet {
                    CompletionReportView(issue: issue)
                        .environmentObject(issueStore)
                } else {
                    StatusUpdateView(issue: issue)
                        .environmentObject(issueStore)
                }
            }
            .onChange(of: selectedIssue) { _, new in
                if new == nil {
                    showCompletionSheet = false
                }
            }
        }
    }

    // MARK: - 툴바

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 4) {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundColor(.zoominBlue)
                    .font(.system(size: 14))
                Text("관리자 모드")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.zoominBlue)
            }
        }
    }

    // MARK: - 1. 요약 카드 섹션

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("전체 신고 현황")
                        .font(ZOOMINFont.title3)
                        .foregroundColor(.textPrimary)
                    Text("우선순위 순으로 정렬되어 있습니다")
                        .font(ZOOMINFont.micro)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                // 전체 건수 배지
                Text("\(issueStore.issues.count)건")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.zoominBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.zoominBlueLight)
                    .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
            }

            // 상태별 카운트 4칸
            HStack(spacing: 8) {
                AdminStatChip(label: "접수됨",  count: receivedCount,   color: .statusReceived)
                AdminStatChip(label: "검토 중", count: reviewingCount,  color: .statusReviewing)
                AdminStatChip(label: "처리 중", count: inProgressCount, color: .statusInProgress)
                AdminStatChip(label: "완료",    count: completedCount,  color: .statusCompleted)
            }
        }
        .zoominCard()
    }

    // MARK: - 2. 필터 바

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {

                // 전체 버튼
                FilterChip(
                    label: "전체 (\(issueStore.issues.count))",
                    isSelected: selectedFilter == nil
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = nil
                    }
                }

                // 상태별 버튼
                ForEach(IssueStatus.allCases, id: \.self) { status in
                    let count = issueStore.issues.filter { $0.status == status }.count
                    FilterChip(
                        label: "\(status.displayName) (\(count))",
                        isSelected: selectedFilter == status,
                        accentColor: status.badgeColor
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = (selectedFilter == status) ? nil : status
                        }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - 3. 이슈 목록 섹션

    private var issueListSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 섹션 헤더
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
                Text("우선순위 높은 순")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(filteredIssues.count)건")
                    .font(ZOOMINFont.caption)
                    .foregroundColor(.textTertiary)
            }

            if filteredIssues.isEmpty {
                // 빈 상태
                ZOOMINEmptyStateView(
                    mood: .done,
                    title: "해당 신고가 없습니다",
                    message: "선택한 필터에 해당하는\n신고가 없어요"
                )
                .frame(maxWidth: .infinity)
                .zoominCard()
            } else {
                // 이슈 카드 목록
                LazyVStack(spacing: 10) {
                    ForEach(filteredIssues) { issue in
                        AdminIssueCard(issue: issue) {
                            // 완료 상태면 완료 보고서 시트, 아니면 상태 변경 시트
                            showCompletionSheet = false
                            selectedIssue = issue
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 관리자 통계 칩

private struct AdminStatChip: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(ZOOMINFont.title2)
                .foregroundColor(color)
            Text(label)
                .font(ZOOMINFont.micro)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - 필터 칩

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var accentColor: Color = .zoominBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(ZOOMINFont.captionBold)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? accentColor : Color.surfacePrimary)
                .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                        .stroke(
                            isSelected ? accentColor : Color.textTertiary.opacity(0.4),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - 관리자 이슈 카드

struct AdminIssueCard: View {
    let issue: Issue
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {

                // ── 상단: 우선순위 강조 바 (높음이면 강조)
                if issue.priorityLevel == .high {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("우선순위 높음 — 즉각 처리 필요")
                            .font(ZOOMINFont.micro)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.vertical, 7)
                    .background(Color.riskCritical)
                }

                // ── 카드 본문 ────────────────────────────────────────
                HStack(alignment: .top, spacing: 12) {

                    // 왼쪽: 사진 썸네일 or 카테고리 아이콘
                    photoOrIcon

                    // 가운데: 텍스트 정보
                    VStack(alignment: .leading, spacing: 6) {

                        // 제목 + 상태 배지
                        HStack(alignment: .top) {
                            Text(issue.title)
                                .font(ZOOMINFont.bodyBold)
                                .foregroundColor(.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 8)
                            ZOOMINStatusBadge(status: issue.status)
                        }

                        // 카테고리
                        HStack(spacing: 4) {
                            Image(systemName: issue.category.symbolName)
                                .font(.system(size: 11))
                                .foregroundColor(issue.category.markerColor)
                            Text(issue.category.displayName)
                                .font(ZOOMINFont.caption)
                                .foregroundColor(.textSecondary)
                        }

                        // 우선순위 점수 바
                        ZOOMINPriorityBar(score: Double(issue.priorityScore))

                        // 하단 메타 정보
                        HStack(spacing: 10) {
                            // 지지 수
                            HStack(spacing: 3) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.zoominBlue)
                                Text("\(issue.supportCount)")
                                    .font(ZOOMINFont.captionBold)
                                    .foregroundColor(.zoominBlue)
                            }

                            // 안전 위험도
                            HStack(spacing: 3) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 11))
                                    .foregroundColor(.riskCritical)
                                Text("위험 \(issue.safetyRisk)")
                                    .font(ZOOMINFont.caption)
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            // 신고일
                            Text(issue.reportDate.formatted(.dateTime.month().day()))
                                .font(ZOOMINFont.micro)
                                .foregroundColor(.textTertiary)

                            // 이동 화살표
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .padding(ZOOMINLayout.paddingMedium)
            }
        }
        .buttonStyle(.plain)
        .background(Color.surfacePrimary)
        .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
        .shadow(
            color: issue.priorityLevel == .high
                ? Color.riskCritical.opacity(0.15)
                : Color.black.opacity(ZOOMINLayout.shadowOpacity),
            radius: ZOOMINLayout.shadowRadius,
            x: 0, y: ZOOMINLayout.shadowY
        )
        .overlay(
            // 우선순위 높으면 테두리 강조
            RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                .stroke(
                    issue.priorityLevel == .high
                        ? Color.riskCritical.opacity(0.4)
                        : Color.clear,
                    lineWidth: 1.5
                )
        )
    }

    // 사진 썸네일 or 카테고리 아이콘 뷰
    @ViewBuilder
    private var photoOrIcon: some View {
        Group {
            if let data = issue.photoData, let uiImg = UIImage(data: data) {
                // 실제 첨부 사진
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else {
                // 카테고리 아이콘 플레이스홀더
                ZStack {
                    Color(issue.category.markerColor).opacity(0.12)
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(issue.category.markerColor)
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
    }
}

// MARK: - Preview

#Preview {
    AdminDashboardView()
        .environmentObject(IssueStore())
}
