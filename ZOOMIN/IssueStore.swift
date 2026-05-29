// IssueStore.swift
// ZOOMIN - Shared store file
// ⚠️ 팀 공용 파일: 이 파일은 모든 팀원이 동일하게 사용합니다. 절대 수정하지 마세요.

import Foundation
import Combine

/// ZOOMIN 앱의 전체 신고 데이터를 관리하는 Observable Store
/// - ContentView에서 @StateObject로 한 번만 생성
/// - 모든 하위 뷰에서 @EnvironmentObject로 접근
final class IssueStore: ObservableObject {

    // MARK: - Published 상태

    @Published var issues: [Issue]

    // MARK: - 초기화 (샘플 데이터 포함)

    init() {
        self.issues = IssueStore.makeSampleIssues()
    }

    // MARK: - 샘플 데이터 (서울 중심부 좌표)

    private static func makeSampleIssues() -> [Issue] {
        [
            Issue(
                title: "간선도로 포트홀 다수 발생",
                category: .roadDamage,
                description: "강남대로 북측 2차선에 지름 30cm 이상 포트홀이 3개 연속 발생했습니다. 차량 타이어 파손 및 오토바이 낙차 사고 위험이 높습니다. 야간에는 식별이 어려워 즉각적인 긴급 보수가 필요합니다.",
                latitude: 37.5665,
                longitude: 126.9780,
                supportCount: 21,
                safetyRisk: 5,
                urgency: 5,
                publicImpact: 5,
                status: .inProgress,
                rewardPoints: 45,
                isMyReport: false
            ),
            Issue(
                title: "보행자 통학로 보도 침하 및 단차",
                category: .sidewalkDamage,
                description: "초등학교 통학로 구간 보도블록이 최대 5cm 침하되어 단차가 발생했습니다. 우천 시 물웅덩이가 생겨 어린이와 고령자의 보행 안전을 위협합니다. 균열 길이 약 15m로 확대되고 있습니다.",
                latitude: 37.5700,
                longitude: 126.9820,
                supportCount: 14,
                safetyRisk: 4,
                urgency: 4,
                publicImpact: 5,
                status: .reviewing,
                rewardPoints: 20,
                isMyReport: false
            ),
            Issue(
                title: "교차로 가로등 전면 소등",
                category: .streetlightFailure,
                description: "주요 교차로 내 가로등 4주 전체가 5일째 소등 상태입니다. 야간 차량·보행자 시야 확보가 불가능하며, 인근 CCTV도 야간 영상 품질이 저하되어 범죄 예방 기능이 상실되었습니다.",
                latitude: 37.5630,
                longitude: 126.9750,
                supportCount: 9,
                safetyRisk: 5,
                urgency: 5,
                publicImpact: 4,
                status: .received,
                rewardPoints: 10,
                isMyReport: false
            ),
            Issue(
                title: "지하차도 배수펌프 고장으로 침수 위험",
                category: .drainageBlocked,
                description: "지하차도 배수펌프 2대 중 1대가 고장나 강우 시 침수 위험이 있습니다. 기상청 주간 강수 예보가 있어 긴급 점검이 필요합니다. 과거 동일 구간 침수로 차량 2대 피해 전례가 있습니다.",
                latitude: 37.5645,
                longitude: 126.9800,
                supportCount: 7,
                safetyRisk: 5,
                urgency: 5,
                publicImpact: 4,
                status: .received,
                rewardPoints: 10,
                isMyReport: false
            ),
            Issue(
                title: "재개발 공사장 방호시설 붕괴",
                category: .constructionSafetyRisk,
                description: "재개발 공사현장 외곽 방호벽 30m 구간이 기울어져 보행로로 넘어질 위험이 있습니다. 안전모·안전선 없이 작업자가 고소 작업 중이며, 낙하물 방지망도 설치되지 않았습니다.",
                latitude: 37.5680,
                longitude: 126.9760,
                supportCount: 3,
                safetyRisk: 5,
                urgency: 5,
                publicImpact: 5,
                status: .received,
                rewardPoints: 10,
                isMyReport: false
            ),
            Issue(
                title: "노후 육교 난간 부식 및 바닥 균열",
                category: .bridgeInfraRisk,
                description: "1980년대 준공 육교의 난간 용접부 부식이 심각하고, 바닥판 콘크리트에 폭 3mm 이상 균열이 다수 발생했습니다. 정밀 안전진단이 시급하며, 통행량이 많은 구간이라 즉각적인 접근 제한 검토가 필요합니다.",
                latitude: 37.5655,
                longitude: 126.9770,
                supportCount: 12,
                safetyRisk: 5,
                urgency: 4,
                publicImpact: 4,
                status: .reviewing,
                rewardPoints: 20,
                isMyReport: true
            )
        ]
    }

    // MARK: - 신고 추가

    /// 새로운 신고를 추가합니다.
    /// - Parameters:
    ///   - title: 신고 제목
    ///   - category: 카테고리
    ///   - description: 상세 설명
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - photoData: 카메라로 찍은 사진 Data (optional)
    ///   - safetyRisk: 안전 위험도 (1~5)
    ///   - urgency: 긴급도 (1~5)
    ///   - publicImpact: 공공 영향도 (1~5)
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
        // 사진 첨부 시 추가 5포인트 보너스
        let basePoints = 10
        let photoBonus = photoData != nil ? 5 : 0

        let newIssue = Issue(
            title: title,
            category: category,
            description: description,
            latitude: latitude,
            longitude: longitude,
            photoData: photoData,
            supportCount: 0,
            safetyRisk: safetyRisk,
            urgency: urgency,
            publicImpact: publicImpact,
            status: .received,
            reportDate: Date(),
            rewardPoints: basePoints + photoBonus,
            isMyReport: true  // 직접 신고한 건으로 마킹
        )
        issues.append(newIssue)
    }

    // MARK: - 지지 (Support)

    /// 특정 신고에 지지 1회를 추가합니다.
    /// - Parameter issueID: 지지할 신고의 UUID
    func supportIssue(issueID: UUID) {
        guard let index = issues.firstIndex(where: { $0.id == issueID }) else { return }
        issues[index].supportCount += 1
        // supportScore는 computed property이므로 자동으로 재계산됩니다.
    }

    // MARK: - 상태 업데이트 (관리자용)

    /// 신고의 처리 상태를 변경합니다.
    /// - Parameters:
    ///   - issueID: 변경할 신고의 UUID
    ///   - newStatus: 새로운 상태
    func updateStatus(issueID: UUID, newStatus: IssueStatus) {
        guard let index = issues.firstIndex(where: { $0.id == issueID }) else { return }
        issues[index].status = newStatus

        // 완료 상태로 변경 시 완료일 자동 설정
        if newStatus == .completed {
            issues[index].completionDate = Date()
            // 완료 보상 추가 (+30)
            issues[index].rewardPoints += 30
        }
        // 검토 단계로 변경 시 추가 보상 (+10)
        if newStatus == .reviewing {
            issues[index].rewardPoints += 10
        }
    }

    // MARK: - 완료 보고 추가 (관리자용)

    /// 처리 완료 보고서를 작성합니다.
    /// - Parameters:
    ///   - issueID: 완료 처리할 신고의 UUID
    ///   - summary: 완료 처리 요약 내용
    func addCompletionReport(issueID: UUID, summary: String) {
        guard let index = issues.firstIndex(where: { $0.id == issueID }) else { return }
        issues[index].completionSummary = summary
        issues[index].status = .completed
        issues[index].completionDate = Date()
        // 완료 피드백 포인트 (+5)
        issues[index].rewardPoints += 5
    }

    // MARK: - Computed: 필터링된 목록

    /// 내가 직접 신고한 건 목록
    var myIssues: [Issue] {
        issues.filter { $0.isMyReport }
    }

    /// 우선순위 점수 내림차순 정렬 (관리자 대시보드용)
    var sortedByPriority: [Issue] {
        issues.sorted { $0.priorityScore > $1.priorityScore }
    }

    /// 내 신고들의 총 보상 포인트
    var totalRewardPoints: Int {
        myIssues.reduce(0) { $0 + $1.rewardPoints }
    }
}
