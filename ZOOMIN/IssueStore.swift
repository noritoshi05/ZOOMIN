// IssueStore.swift
// ZOOMIN - Shared store file
// ⚠️ 팀 공용 파일: 이 파일은 모든 팀원이 동일하게 사용합니다. 절대 수정하지 마세요.

// IssueStore.swift
// ZOOMIN - Shared store file
// Firestore 실시간 연동 버전 (Member 4 수정)

import Foundation
import Combine
import FirebaseFirestore

final class IssueStore: ObservableObject {

    // MARK: - Published 상태
    @Published var issues: [Issue] = []

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - 초기화
    init() {
        startListening()
        SeedData.uploadIfEmpty()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - 실시간 리스닝 시작

    /// Firestore issues 컬렉션을 실시간으로 구독
    func startListening() {
        listener = db.collection("issues")
            .order(by: "reportDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Firestore 리스닝 오류: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
                    self.issues = documents.compactMap { doc in
                        self.issueFromDocument(doc)
                    }
                }
            }
    }

    // MARK: - Firestore 문서 → Issue 변환

    private func issueFromDocument(_ doc: QueryDocumentSnapshot) -> Issue? {
        let data = doc.data()

        guard
            let title         = data["title"] as? String,
            let categoryRaw   = data["category"] as? String,
            let category      = IssueCategory(rawValue: categoryRaw),
            let description   = data["description"] as? String,
            let latitude      = data["latitude"] as? Double,
            let longitude     = data["longitude"] as? Double,
            let supportCount  = data["supportCount"] as? Int,
            let safetyRisk    = data["safetyRisk"] as? Int,
            let urgency       = data["urgency"] as? Int,
            let publicImpact  = data["publicImpact"] as? Int,
            let statusRaw     = data["status"] as? String,
            let status        = IssueStatus(rawValue: statusRaw),
            let rewardPoints  = data["rewardPoints"] as? Int,
            let isMyReport    = data["isMyReport"] as? Bool
        else { return nil }

        let reportDate: Date
        if let ts = data["reportDate"] as? Timestamp {
            reportDate = ts.dateValue()
        } else {
            reportDate = Date()
        }

        let completionDate: Date?
        if let ts = data["completionDate"] as? Timestamp {
            completionDate = ts.dateValue()
        } else {
            completionDate = nil
        }

        let id = UUID(uuidString: doc.documentID) ?? UUID()

        return Issue(
            id:                id,
            title:             title,
            category:          category,
            description:       description,
            latitude:          latitude,
            longitude:         longitude,
            photoData:         nil,
            supportCount:      supportCount,
            safetyRisk:        safetyRisk,
            urgency:           urgency,
            publicImpact:      publicImpact,
            status:            status,
            reportDate:        reportDate,
            completionDate:    completionDate,
            completionSummary: data["completionSummary"] as? String,
            rewardPoints:      rewardPoints,
            isMyReport:        isMyReport
        )
    }

    // MARK: - Issue → Firestore 딕셔너리 변환

    private func documentData(from issue: Issue) -> [String: Any] {
        var data: [String: Any] = [
            "title":         issue.title,
            "category":      issue.category.rawValue,
            "description":   issue.description,
            "latitude":      issue.latitude,
            "longitude":     issue.longitude,
            "supportCount":  issue.supportCount,
            "safetyRisk":    issue.safetyRisk,
            "urgency":       issue.urgency,
            "publicImpact":  issue.publicImpact,
            "status":        issue.status.rawValue,
            "rewardPoints":  issue.rewardPoints,
            "isMyReport":    issue.isMyReport,
            "reportDate":    Timestamp(date: issue.reportDate)
        ]
        if let completionDate = issue.completionDate {
            data["completionDate"] = Timestamp(date: completionDate)
        }
        if let summary = issue.completionSummary {
            data["completionSummary"] = summary
        }
        return data
    }

    // MARK: - 신고 추가

    func addIssue(
        title: String,
        category: IssueCategory,
        description: String,
        latitude: Double,
        longitude: Double,
        photoData: Data? = nil,
        safetyRisk: Int,
        urgency: Int,
        publicImpact: Int
    ) {
        let basePoints = 10
        let photoBonus = photoData != nil ? 5 : 0

        let newIssue = Issue(
            title:        title,
            category:     category,
            description:  description,
            latitude:     latitude,
            longitude:    longitude,
            photoData:    photoData,
            supportCount: 0,
            safetyRisk:   safetyRisk,
            urgency:      urgency,
            publicImpact: publicImpact,
            status:       .received,
            reportDate:   Date(),
            rewardPoints: basePoints + photoBonus,
            isMyReport:   true
        )

        // Firestore에 저장
        db.collection("issues")
            .document(newIssue.id.uuidString)
            .setData(documentData(from: newIssue)) { error in
                if let error = error {
                    print("신고 추가 오류: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - 지지

    func supportIssue(issueID: UUID) {
        let docRef = db.collection("issues").document(issueID.uuidString)
        docRef.updateData([
            "supportCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("지지 오류: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 상태 업데이트 (관리자용)

    func updateStatus(issueID: UUID, newStatus: IssueStatus) {
        guard let index = issues.firstIndex(where: { $0.id == issueID }) else { return }

        var updateData: [String: Any] = ["status": newStatus.rawValue]

        var pointsToAdd = 0
        if newStatus == .completed {
            updateData["completionDate"] = Timestamp(date: Date())
            pointsToAdd = 30
        }
        if newStatus == .reviewing {
            pointsToAdd = 10
        }

        let newPoints = issues[index].rewardPoints + pointsToAdd
        updateData["rewardPoints"] = newPoints

        db.collection("issues").document(issueID.uuidString)
            .updateData(updateData) { error in
                if let error = error {
                    print("상태 업데이트 오류: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - 완료 보고 추가 (관리자용)

    func addCompletionReport(issueID: UUID, summary: String) {
        guard let index = issues.firstIndex(where: { $0.id == issueID }) else { return }

        let newPoints = issues[index].rewardPoints + 5

        db.collection("issues").document(issueID.uuidString)
            .updateData([
                "completionSummary": summary,
                "status":            IssueStatus.completed.rawValue,
                "completionDate":    Timestamp(date: Date()),
                "rewardPoints":      newPoints
            ]) { error in
                if let error = error {
                    print("완료 보고 오류: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - Computed

    var myIssues: [Issue] {
        issues.filter { $0.isMyReport }
    }

    var sortedByPriority: [Issue] {
        issues.sorted { $0.priorityScore > $1.priorityScore }
    }

    var totalRewardPoints: Int {
        myIssues.reduce(0) { $0 + $1.rewardPoints }
    }
    
    // MARK: - 신고 삭제 (내가 직접)

    func deleteIssue(issueID: UUID) {
        db.collection("issues").document(issueID.uuidString)
            .delete { error in
                if let error = error {
                    print("삭제 오류: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - 완료 후 30일 지난 신고 자동 삭제

    func deleteExpiredIssues() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let expired = issues.filter {
            $0.status == .completed &&
            ($0.completionDate ?? Date()) < thirtyDaysAgo
        }
        for issue in expired {
            deleteIssue(issueID: issue.id)
        }
    }
}
