// CompletionReportView.swift
// ZOOMIN — Member 4
// Role: Admin completion report / Resolution summary / Reward point payout

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

                        // 1. Issue summary
                        issueSnapshotCard

                        // 2. Report form
                        reportFormSection

                        // 3. Reward preview after submission
                        rewardPreviewCard

                        // 4. Submit button
                        submitButton
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Completion Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
            .alert("Mark as completed?", isPresented: $showConfirm) {
                Button("Mark Complete", role: .destructive) { submitReport() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Status will be set to Completed and reward points will be sent to the reporter.")
            }
            .alert("Completed ✅", isPresented: $isDone) {
                Button("OK") { dismiss() }
            } message: {
                Text("Report saved and points awarded to the reporter.")
            }
        }
    }

    // MARK: - Issue Snapshot Card

    private var issueSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.statusCompleted)
                    .font(.system(size: 14))
                Text("Write Completion Report")
                    .font(ZOOMINFont.title3)
                    .foregroundColor(.textPrimary)
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                // Category icon
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

            // Brief report content
            if !issue.description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report Description")
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

    // MARK: - Report Form

    private var reportFormSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Summary of Resolution")
                    .font(ZOOMINFont.title3)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(summaryText.count)/\(maxSummaryLength)")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(
                        summaryText.count > maxSummaryLength ? .riskCritical : .textTertiary
                    )
            }

            // Text editor
            ZStack(alignment: .topLeading) {
                if summaryText.isEmpty {
                    Text("Briefly describe the resolution. e.g. Pothole repaired on June 1, 2024. Monitoring scheduled for 6 months.")
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

            // Minimum character count hint
            if !isSubmittable && !summaryText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                    Text("Please enter at least 10 characters (current: \(summaryText.count))")
                }
                .font(ZOOMINFont.micro)
                .foregroundColor(.statusInProgress)
            }

            // Writing guide
            VStack(alignment: .leading, spacing: 4) {
                Text("Writing Guide")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                ForEach([
                    "Specific resolution method and completion date",
                    "Materials / personnel / equipment used (brief)",
                    "Follow-up monitoring plan (optional)"
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

    // MARK: - Reward Preview

    private var rewardPreviewCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 24))
                .foregroundColor(.rewardGold)

            VStack(alignment: .leading, spacing: 3) {
                Text("Reward for reporter on completion")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
                Text("Points are automatically awarded after submitting the report")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+35 P")
                    .font(ZOOMINFont.title2)
                    .foregroundColor(.rewardGold)
                Text("Complete+Feedback")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }
        }
        .zoominCard()
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            showConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                Text("Submit Completion Report")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominPrimaryButton()
        .opacity(isSubmittable ? 1.0 : 0.45)
        .disabled(!isSubmittable)
    }

    // MARK: - Submit Action

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

