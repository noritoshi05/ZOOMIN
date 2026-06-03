// SeedData.swift
// ZOOMIN — 연세대 주변 실제 예시 데이터 Firestore 업로드용
// 앱 첫 실행 시 Firestore가 비어있으면 자동으로 샘플 데이터 업로드

import Foundation
import FirebaseFirestore

struct SeedData {

    static let db = Firestore.firestore()

    // Firestore가 비어있을 때만 샘플 데이터 업로드
    static func uploadIfEmpty() {
        db.collection("issues").limit(to: 1).getDocuments { snapshot, _ in
            guard let snapshot = snapshot, snapshot.isEmpty else { return }
            uploadSamples()
        }
    }

    static func uploadSamples() {
        for issue in sampleIssues {
            var data: [String: Any] = [
                "title":        issue.title,
                "category":     issue.category.rawValue,
                "description":  issue.description,
                "latitude":     issue.latitude,
                "longitude":    issue.longitude,
                "supportCount": issue.supportCount,
                "safetyRisk":   issue.safetyRisk,
                "urgency":      issue.urgency,
                "publicImpact": issue.publicImpact,
                "status":       issue.status.rawValue,
                "rewardPoints": issue.rewardPoints,
                "isMyReport":   issue.isMyReport,
                "reportDate":   Timestamp(date: issue.reportDate)
            ]
            if let summary = issue.completionSummary {
                data["completionSummary"] = summary
            }
            if let date = issue.completionDate {
                data["completionDate"] = Timestamp(date: date)
            }
            db.collection("issues")
                .document(issue.id.uuidString)
                .setData(data)
        }
        print("✅ 연세대 주변 샘플 데이터 업로드 완료")
    }

    // MARK: - 연세대 주변 실제 위치 기반 샘플 데이터

    static let sampleIssues: [Issue] = [

        // 1. 연세로 보도블록 파손 — 연세대 정문 앞
        Issue(
            title: "연세로 정문 앞 보도블록 파손",
            category: .sidewalkDamage,
            description: "연세대학교 정문 앞 연세로 보행자 구간에 보도블록 4장이 깨지고 들려 있습니다. 비가 오면 물이 고여 보행 중 미끄러짐 사고가 반복되고 있으며, 특히 등하교 시간대 혼잡 시 낙상 위험이 큽니다. 휠체어·유모차 통행도 불가 상태입니다.",
            latitude: 37.5645,
            longitude: 126.9388,
            supportCount: 18,
            safetyRisk: 4,
            urgency: 4,
            publicImpact: 5,
            status: .inProgress,
            rewardPoints: 30,
            isMyReport: false
        ),

        // 2. 신촌역 사거리 포트홀 — 신촌로터리
        Issue(
            title: "신촌역 사거리 포트홀 3개 발생",
            category: .roadDamage,
            description: "신촌역 2번 출구 앞 신촌로 사거리 1차선에 지름 25cm 포트홀이 3개 연속 발생했습니다. 출퇴근 시간대 차량 통행량이 매우 많아 타이어 파손 사고가 이미 2건 발생했으며 오토바이 낙차 위험도 높습니다. 야간 식별이 어려워 긴급 보수가 필요합니다.",
            latitude: 37.5551,
            longitude: 126.9368,
            supportCount: 24,
            safetyRisk: 5,
            urgency: 5,
            publicImpact: 5,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 3. 백양로 가로등 고장 — 연세대 백양로
        Issue(
            title: "백양로 가로등 4개 연속 소등",
            category: .streetlightFailure,
            description: "연세대학교 백양로 중앙도서관 구간 가로등 4개가 1주일째 소등 상태입니다. 야간 강의 후 귀가하는 학생들의 시야 확보가 불가능하며 CCTV 화질도 저하되어 있습니다. 최근 인근에서 야간 안전사고가 신고된 바 있어 즉각적인 수리가 필요합니다.",
            latitude: 37.5652,
            longitude: 126.9372,
            supportCount: 31,
            safetyRisk: 4,
            urgency: 5,
            publicImpact: 4,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),

        // 4. 홍익문화공원 배수구 막힘 — 홍대 인근
        Issue(
            title: "홍익문화공원 앞 배수구 막힘",
            category: .drainageBlocked,
            description: "홍익문화공원 정문 앞 와우산로 배수구가 낙엽과 쓰레기로 완전히 막혀있습니다. 지난 비에 보행로가 침수돼 인근 상가 앞까지 물이 넘쳤습니다. 이번 주 강수 예보가 있어 재침수 위험이 큽니다. 긴급 청소 요청드립니다.",
            latitude: 37.5519,
            longitude: 126.9238,
            supportCount: 9,
            safetyRisk: 3,
            urgency: 5,
            publicImpact: 3,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 5. 연대 정문 공사장 안전망 — 공사 위험
        Issue(
            title: "연대 정문 인근 공사장 낙하물 위험",
            category: .constructionSafetyRisk,
            description: "연세로 공사구간 외벽 안전망이 일부 탈락해 보행자 머리 위로 낙하물 위험이 있습니다. 안전 고깔과 펜스가 설치돼 있지만 야간에는 식별이 어렵고 보행로가 좁아 통행이 위험합니다. 공사 시간도 소음 기준을 초과하고 있습니다.",
            latitude: 37.5640,
            longitude: 126.9382,
            supportCount: 13,
            safetyRisk: 5,
            urgency: 5,
            publicImpact: 4,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 6. 신촌 고가보도 난간 부식 — 완료 처리된 케이스
        Issue(
            title: "신촌 굴다리 난간 부식 및 균열",
            category: .bridgeInfraRisk,
            description: "신촌역 굴다리 난간 용접부에 부식이 심각하고 콘크리트 균열 폭이 3mm 이상입니다. 통행량이 많아 즉각적인 정밀 안전진단이 필요합니다.",
            latitude: 37.5548,
            longitude: 126.9362,
            supportCount: 7,
            safetyRisk: 5,
            urgency: 4,
            publicImpact: 4,
            status: .completed,
            reportDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            completionDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            completionSummary: "정밀 안전진단 완료 후 난간 용접부 전체 재도장 및 균열 에폭시 충전 처리 완료. 향후 6개월 주기 모니터링 예정.",
            rewardPoints: 55,
            isMyReport: true
        ),

        // 7. 이화여대 앞 보도 침하 — 연세대 인근
        Issue(
            title: "이화여대 앞 대현동 보도 침하",
            category: .sidewalkDamage,
            description: "이화여대 정문 앞 대현동 보도블록이 최대 4cm 침하되어 단차가 생겼습니다. 고령자와 유모차 통행이 잦은 구간으로 낙상 사고 위험이 높습니다.",
            latitude: 37.5616,
            longitude: 126.9466,
            supportCount: 11,
            safetyRisk: 3,
            urgency: 3,
            publicImpact: 4,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),

        // 8. 연대 후문 쪽 기타 시설물 파손
        Issue(
            title: "연대 후문 공중화장실 시설 파손",
            category: .other,
            description: "연세대학교 후문 인근 공중화장실 출입문 경첩이 파손돼 문이 제대로 닫히지 않습니다. 냉·난방 기능도 작동하지 않아 이용이 불편합니다.",
            latitude: 37.5672,
            longitude: 126.9358,
            supportCount: 5,
            safetyRisk: 1,
            urgency: 2,
            publicImpact: 2,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        )
    ]
}
