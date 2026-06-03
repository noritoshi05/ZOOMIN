// StatusUpdateView.swift
// ZOOMIN — Member 4 담당
// 역할: 관리자 상태 변경 시트 (접수됨 → 검토 중 → 처리 중 → 완료)

import SwiftUI

struct StatusUpdateView: View {

    @EnvironmentObject var issueStore: IssueStore
    @Environment(\.dismiss) private var dismiss

    let issue: Issue

    @State private var selectedStatus: IssueStatus
    @State private var showCompletionReport: Bool = false
    @State private var confirmUpdate: Bool = false

    init(issue: Issue) {
        self.issue = issue
        _selectedStatus = State(initialValue: issue.status)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ZOOMINLayout.paddingMedium) {

                        // 1. 이슈 요약 카드
                        issueSnapshotCard

                        // 2. 상태 선택 섹션
                        statusPickerSection

                        // 3. 상태 변경 안내
                        rewardInfoCard

                        // 4. 완료 처리 시 보고서 버튼
                        if selectedStatus == .completed && (issue.completionSummary == nil || issue.completionSummary?.isEmpty == true) {
                            completionReportButton
                        } else if selectedStatus == .completed {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.statusCompleted)
                                Text("완료 보고서가 이미 작성되었습니다")
                                    .font(ZOOMINFont.captionBold)
                                    .foregroundColor(.statusCompleted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ZOOMINLayout.paddingMedium)
                            .background(Color.statusCompleted.opacity(0.08))
                            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
                        }

                        // 5. 저장 버튼
                        saveButton
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("상태 업데이트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
            .sheet(isPresented: $showCompletionReport) {
                CompletionReportView(issue: issue)
                    .environmentObject(issueStore)
            }
            .alert("상태를 변경하시겠어요?", isPresented: $confirmUpdate) {
                Button("변경", role: .destructive) { applyStatusUpdate() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("'\(issue.status.displayName)' → '\(selectedStatus.displayName)'")
            }
        }
    }

    // MARK: - 이슈 요약 카드

    private var issueSnapshotCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // 카테고리 아이콘
            ZStack {
                Color(issue.category.markerColor).opacity(0.12)
                Image(systemName: issue.category.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(issue.category.markerColor)
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))

            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title)
                    .font(ZOOMINFont.bodyBold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                Text(issue.category.displayName)
                    .font(ZOOMINFont.caption)
                    .foregroundColor(.textSecondary)

                HStack(spacing: 8) {
                    // 현재 상태
                    ZOOMINStatusBadge(status: issue.status)
                    // 우선순위 점수
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.zoominBlue)
                        Text("점수 \(issue.priorityScore)")
                            .font(ZOOMINFont.captionBold)
                            .foregroundColor(.zoominBlue)
                    }
                }
            }
            Spacer()
        }
        .zoominCard()
    }

    // MARK: - 상태 선택 섹션

    private var statusPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상태 선택")
                .font(ZOOMINFont.title3)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(IssueStatus.allCases, id: \.self) { status in
                    StatusOptionRow(
                        status: status,
                        isSelected: selectedStatus == status,
                        isCurrent: issue.status == status,
                        isDisabled: isStatusDisabled(status)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedStatus = status
                        }
                    }
                }
            }

            // 상태 흐름 안내
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
                Text("상태는 순서대로만 변경할 수 있습니다")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }
        }
        .zoominCard()
    }

    // 뒤로 가는 상태는 비활성화
    private func isStatusDisabled(_ status: IssueStatus) -> Bool {
        let order: [IssueStatus] = [.received, .reviewing, .inProgress, .completed]
        guard let currentIdx = order.firstIndex(of: issue.status),
              let targetIdx  = order.firstIndex(of: status) else { return true }
        return targetIdx < currentIdx
    }

    // MARK: - 보상 안내 카드

    private var rewardInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.rewardGold)
                    .font(.system(size: 13))
                Text("상태 변경 시 자동 보상")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                RewardInfoRow(icon: "magnifyingglass",
                              label: "검토 중으로 변경",
                              reward: "+10 P",
                              color: .statusReviewing)
                RewardInfoRow(icon: "checkmark.circle.fill",
                              label: "완료 처리",
                              reward: "+30 P",
                              color: .statusCompleted)
            }
        }
        .zoominCard()
    }

    // MARK: - 완료 보고서 버튼

    private var completionReportButton: some View {
        Button {
            showCompletionReport = true
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                Text("완료 보고서 작성하기")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominSecondaryButton()
    }

    // MARK: - 저장 버튼

    private var saveButton: some View {
        Button {
            if selectedStatus == issue.status {
                dismiss()
            } else {
                confirmUpdate = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName:
                        selectedStatus == issue.status
                        ? "xmark.circle.fill"
                        : "checkmark.circle.fill"
                )
                Text(selectedStatus == issue.status ? "변경 없음 (닫기)" : "상태 저장")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominPrimaryButton()
    }

    // MARK: - 상태 업데이트 실행

    private func applyStatusUpdate() {
        issueStore.updateStatus(issueID: issue.id, newStatus: selectedStatus)
        dismiss()
    }
}

// MARK: - 상태 선택 행

private struct StatusOptionRow: View {
    let status: IssueStatus
    let isSelected: Bool
    let isCurrent: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 상태 아이콘
                ZStack {
                    Circle()
                        .fill(isDisabled
                              ? Color.textTertiary.opacity(0.1)
                              : status.badgeColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: status.symbolName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDisabled ? .textTertiary : status.badgeColor)
                }

                // 라벨
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(status.displayName)
                            .font(ZOOMINFont.bodyBold)
                            .foregroundColor(isDisabled ? .textTertiary : .textPrimary)
                        if isCurrent {
                            Text("현재")
                                .font(ZOOMINFont.micro)
                                .foregroundColor(.zoominBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.zoominBlueLight)
                                .cornerRadius(4)
                        }
                    }
                    if isDisabled {
                        Text("이전 단계로 되돌릴 수 없습니다")
                            .font(ZOOMINFont.micro)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()

                // 선택 라디오
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .zoominBlue : .textTertiary.opacity(0.5))
            }
            .padding(ZOOMINLayout.paddingMedium)
            .background(
                isSelected
                    ? Color.zoominBlueLight
                    : Color.surfacePrimary
            )
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .stroke(
                        isSelected ? Color.zoominBlue.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1.0)
    }
}

// MARK: - 보상 안내 행

private struct RewardInfoRow: View {
    let icon: String
    let label: String
    let reward: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .frame(width: 18)
            Text(label)
                .font(ZOOMINFont.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(reward)
                .font(ZOOMINFont.captionBold)
                .foregroundColor(.rewardGold)
        }
    }
}

// MARK: - Preview

#Preview {
    StatusUpdateView(issue: IssueStore().issues[0])
        .environmentObject(IssueStore())
}
