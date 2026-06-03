// CompletionReportView.swift
// ZOOMIN — Member 4 담당
// 역할: 관리자 완료 보고서 작성 / 처리 결과 요약 / 보상 포인트 지급

import SwiftUI

struct CompletionReportView: View {

    @EnvironmentObject var issueStore: IssueStore
    @Environment(\.dismiss) private var dismiss

    let issue: Issue

    @State private var summaryText: String = ""
    @State private var showConfirm: Bool = false
    @State private var isDone: Bool = false

    private let maxSummaryLength = 300
    private var isSubmittable: Bool {
        summaryText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ZOOMINLayout.paddingMedium) {

                        // 1. 이슈 요약
                        issueSnapshotCard

                        // 2. 보고서 작성 폼
                        reportFormSection

                        // 3. 제출 후 보상 미리보기
                        rewardPreviewCard

                        // 4. 제출 버튼
                        submitButton
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("완료 보고서")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
            .alert("완료 처리하시겠어요?", isPresented: $showConfirm) {
                Button("완료 처리", role: .destructive) { submitReport() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("처리 완료로 변경되며 주민에게 보상 포인트가 지급됩니다.")
            }
            .alert("완료 처리되었습니다 ✅", isPresented: $isDone) {
                Button("확인") { dismiss() }
            } message: {
                Text("보고서가 저장되고 신고자에게 포인트가 지급되었습니다.")
            }
        }
    }

    // MARK: - 이슈 요약 카드

    private var issueSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.statusCompleted)
                    .font(.system(size: 14))
                Text("처리 완료 보고서 작성")
                    .font(ZOOMINFont.title3)
                    .foregroundColor(.textPrimary)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                // 카테고리 아이콘
                ZStack {
                    Color(issue.category.markerColor).opacity(0.12)
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(issue.category.markerColor)
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))

                VStack(alignment: .leading, spacing: 4) {
                    Text(issue.title)
                        .font(ZOOMINFont.bodyBold)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                    Text(issue.category.displayName)
                        .font(ZOOMINFont.caption)
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 8) {
                        ZOOMINStatusBadge(status: issue.status)
                        ZOOMINPointsBadge(points: issue.rewardPoints)
                    }
                }
                Spacer()
            }

            // 신고 내용 간략 표시
            if !issue.description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("신고 내용")
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(.textSecondary)
                    Text(issue.description)
                        .font(ZOOMINFont.caption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(3)
                }
                .padding(ZOOMINLayout.paddingSmall)
                .background(Color.surfaceSecondary)
                .cornerRadius(ZOOMINLayout.cornerRadiusSmall)
            }
        }
        .zoominCard()
    }

    // MARK: - 보고서 작성 폼

    private var reportFormSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("처리 결과 요약")
                    .font(ZOOMINFont.title3)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(summaryText.count)/\(maxSummaryLength)")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(
                        summaryText.count > maxSummaryLength ? .riskCritical : .textTertiary
                    )
            }

            // 텍스트 에디터
            ZStack(alignment: .topLeading) {
                if summaryText.isEmpty {
                    Text("처리 내용을 간략히 작성해 주세요.\n예) 포트홀 아스팔트 보수 완료 (2024.06.01 시공), 향후 6개월 추가 모니터링 예정")
                        .font(ZOOMINFont.body)
                        .foregroundColor(.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $summaryText)
                    .font(ZOOMINFont.body)
                    .foregroundColor(.textPrimary)
                    .frame(minHeight: 140)
                    .scrollContentBackground(.hidden)
                    .onChange(of: summaryText) { _, new in
                        if new.count > maxSummaryLength {
                            summaryText = String(new.prefix(maxSummaryLength))
                        }
                    }
            }
            .padding(ZOOMINLayout.paddingSmall)
            .background(Color.surfaceSecondary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .stroke(
                        isSubmittable ? Color.statusCompleted.opacity(0.4) : Color.textTertiary.opacity(0.3),
                        lineWidth: 1
                    )
            )

            // 최소 글자 수 안내
            if !isSubmittable && !summaryText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("최소 10자 이상 입력해 주세요 (현재 \(summaryText.count)자)")
                }
                .font(ZOOMINFont.micro)
                .foregroundColor(.statusInProgress)
            }

            // 작성 가이드
            VStack(alignment: .leading, spacing: 4) {
                Text("작성 가이드")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                ForEach([
                    "구체적인 처리 방법 및 완료 날짜",
                    "사용된 자재·인력·장비 (간략히)",
                    "향후 모니터링 계획 (선택)"
                ], id: \.self) { hint in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundColor(.textTertiary)
                        Text(hint)
                            .font(ZOOMINFont.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
            }
        }
        .zoominCard()
    }

    // MARK: - 보상 미리보기

    private var rewardPreviewCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 24))
                .foregroundColor(.rewardGold)

            VStack(alignment: .leading, spacing: 3) {
                Text("완료 처리 시 신고자 보상")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
                Text("완료 보고서 제출 후 포인트가 자동 지급됩니다")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+35 P")
                    .font(ZOOMINFont.title2)
                    .foregroundColor(.rewardGold)
                Text("완료+피드백")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }
        }
        .zoominCard()
    }

    // MARK: - 제출 버튼

    private var submitButton: some View {
        Button {
            showConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                Text("완료 처리 및 보고서 제출")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominPrimaryButton()
        .opacity(isSubmittable ? 1.0 : 0.45)
        .disabled(!isSubmittable)
    }

    // MARK: - 제출 실행

    private func submitReport() {
        issueStore.addCompletionReport(
            issueID: issue.id,
            summary: summaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        isDone = true
    }
}

// MARK: - Preview

#Preview {
    CompletionReportView(issue: IssueStore().issues[0])
        .environmentObject(IssueStore())
}
