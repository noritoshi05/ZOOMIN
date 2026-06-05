// IssueStore.swift
// ZOOMIN - Shared store file
// Firestore real-time integration version (Member 4 revision)

import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage

final class IssueStore: ObservableObject {

    // MARK: - Published State
    @Published var issues: [Issue] = []

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Initialization
    init() {
        startListening()
        SeedData.uploadIfEmpty()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Start Real-time Listening

    /// Subscribe to Firestore issues collection in real time
    func startListening() {
        listener = db.collection("issues")
            .order(by: "reportDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Firestore listening error: \(error.localizedDescription)")
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

    // MARK: - Firestore Document → Issue Conversion

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
            photoURL:          data["photoURL"] as? String,
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

    // MARK: - Issue → Firestore Dictionary Conversion

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
        if let photoURL = issue.photoURL {
            data["photoURL"] = photoURL
        }
        return data
    }

    // MARK: - Add Report
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

        guard let data = photoData else {
            db.collection("issues").document(newIssue.id.uuidString).setData(documentData(from: newIssue))
            return
        }

        let ref = Storage.storage().reference().child("issue_photos/\(newIssue.id.uuidString).jpg")
        ref.putData(data) { _, error in
            if let error = error { print("Photo upload error: \(error)"); return }
            ref.downloadURL { url, _ in
                var issue = newIssue
                issue.photoURL = url?.absoluteString
                self.db.collection("issues").document(issue.id.uuidString).setData(self.documentData(from: issue))
            }
        }
    }

    // MARK: - Support

    func supportIssue(issueID: UUID) {
        let docRef = db.collection("issues").document(issueID.uuidString)
        docRef.updateData([
            "supportCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Support error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Status Update (Admin)

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
                    print("Status update error: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - Add Completion Report (Admin)

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
                    print("Completion report error: \(error.localizedDescription)")
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
}

