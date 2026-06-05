// StatusUpdateView.swift
// ZOOMIN — Member 4
// Role: Admin status update sheet (Received → Reviewing → In Progress → Completed)

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

                        // 1. Issue snapshot card
                        issueSnapshotCard

                        // 2. Status picker section
                        statusPickerSection

                        // 3. Status change info
                        rewardInfoCard

                        // 4. Completion report button (when marking complete)
                        if selectedStatus == .completed && (issue.completionSummary == nil || issue.completionSummary?.isEmpty == true) {
                            completionReportButton
                        } else if selectedStatus == .completed {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.statusCompleted)
                                Text("Completion report already submitted")
                                    .font(ZOOMINFont.captionBold)
                                    .foregroundColor(.statusCompleted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(ZOOMINLayout.paddingMedium)
                            .background(Color.statusCompleted.opacity(0.08))
                            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
                        }

                        // 5. Save button
                        saveButton
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Status Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
            .sheet(isPresented: $showCompletionReport) {
                CompletionReportView(issue: issue)
                    .environmentObject(issueStore)
            }
            .alert("Change status?", isPresented: $confirmUpdate) {
                Button("Confirm", role: .destructive) { applyStatusUpdate() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("'\(issue.status.displayName)' → '\(selectedStatus.displayName)'")
            }
        }
    }

    // MARK: - Issue Snapshot Card

    private var issueSnapshotCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Category icon
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
                    // Current status
                    ZOOMINStatusBadge(status: issue.status)
                    // Priority score
                    HStack(spacing: 3) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.zoominBlue)
                        Text("Score \(issue.priorityScore)")
                            .font(ZOOMINFont.captionBold)
                            .foregroundColor(.zoominBlue)
                    }
                }
            }
            Spacer()
        }
        .zoominCard()
    }

    // MARK: - Status Picker Section

    private var statusPickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Status")
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

            // Status flow hint
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundColor(.textTertiary)
                Text("Status can only be changed in order")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }
        }
        .zoominCard()
    }

    // Disable reverting to a previous status
    private func isStatusDisabled(_ status: IssueStatus) -> Bool {
        let order: [IssueStatus] = [.received, .reviewing, .inProgress, .completed]
        guard let currentIdx = order.firstIndex(of: issue.status),
              let targetIdx  = order.firstIndex(of: status) else { return true }
        return targetIdx < currentIdx
    }

    // MARK: - Reward Info Card

    private var rewardInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .foregroundColor(.rewardGold)
                    .font(.system(size: 13))
                Text("Auto reward on status change")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                RewardInfoRow(icon: "magnifyingglass",
                              label: "Change to Reviewing",
                              reward: "+10 P",
                              color: .statusReviewing)
                RewardInfoRow(icon: "checkmark.circle.fill",
                              label: "Mark as Completed",
                              reward: "+30 P",
                              color: .statusCompleted)
            }
        }
        .zoominCard()
    }

    // MARK: - Completion Report Button

    private var completionReportButton: some View {
        Button {
            showCompletionReport = true
        } label: {
            HStack {
                Image(systemName: "doc.text.fill")
                Text("Write Completion Report")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominSecondaryButton()
    }

    // MARK: - Save Button

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
                Text(selectedStatus == issue.status ? "No changes (Close)" : "Save Status")
                    .font(ZOOMINFont.bodyBold)
            }
        }
        .zoominPrimaryButton()
    }

    // MARK: - Apply Status Update

    private func applyStatusUpdate() {
        issueStore.updateStatus(issueID: issue.id, newStatus: selectedStatus)
        dismiss()
    }
}

// MARK: - Status Option Row

private struct StatusOptionRow: View {
    let status: IssueStatus
    let isSelected: Bool
    let isCurrent: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Status icon
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

                // Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(status.displayName)
                            .font(ZOOMINFont.bodyBold)
                            .foregroundColor(isDisabled ? .textTertiary : .textPrimary)
                        if isCurrent {
                            Text("Current")
                                .font(ZOOMINFont.micro)
                                .foregroundColor(.zoominBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.zoominBlueLight)
                                .cornerRadius(4)
                        }
                    }
                    if isDisabled {
                        Text("Cannot revert to a previous stage")
                            .font(ZOOMINFont.micro)
                            .foregroundColor(.textTertiary)
                    }
                }

                Spacer()

                // Selection radio
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

// MARK: - Reward Info Row

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

