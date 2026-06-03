// SeedData.swift
// ZOOMIN — Real sample data around Seodaemun-gu for Firestore upload
// Automatically uploads sample data on first launch if Firestore is empty

import Foundation
import FirebaseFirestore

struct SeedData {

    static let db = Firestore.firestore()

    // Upload sample data only when Firestore is empty
    static func uploadIfEmpty() {
        db.collection("issues").limit(to: 1).getDocuments { snapshot, _ in
            guard let snapshot = snapshot, snapshot.isEmpty else { return }
            uploadSamples()
        }
    }

    // Delete all existing and re-upload (call manually if needed)
    static func resetAndUpload() {
        db.collection("issues").getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                uploadSamples()
            }
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
        print("✅ Seodaemun-gu sample data uploaded successfully")
    }

    // MARK: - Sample Data (Seodaemun-gu, Seoul)

    static let sampleIssues: [Issue] = [

        // 1. Road Damage — Yonsei-ro near main gate
        Issue(
            title: "Multiple Potholes on Yonsei-ro",
            category: .roadDamage,
            description: "Three potholes, each approximately 30cm in diameter, have formed in lane 1 near Yonsei University main gate on Yonsei-ro. The road surface has been deteriorating since heavy rainfall last week. Two motorcycle near-miss incidents have already been reported. The potholes are especially dangerous at night when visibility is low. Urgent patching is required before further accidents occur.",
            latitude: 37.5645,
            longitude: 126.9390,
            supportCount: 24,
            safetyRisk: 5,
            urgency: 5,
            publicImpact: 5,
            status: .inProgress,
            rewardPoints: 45,
            isMyReport: false
        ),

        // 2. Sidewalk Damage — Sinchon Station exit 3
        Issue(
            title: "Cracked Sidewalk Blocks Near Sinchon Station Exit 3",
            category: .sidewalkDamage,
            description: "Several sidewalk blocks near Exit 3 of Sinchon Station have cracked and shifted, creating uneven surfaces of up to 4cm. The area sees heavy foot traffic from commuters and university students. Elderly pedestrians and wheelchair users are at particular risk. Water pooling during rain worsens the hazard. The damaged section extends approximately 8 meters.",
            latitude: 37.5551,
            longitude: 126.9369,
            supportCount: 18,
            safetyRisk: 4,
            urgency: 4,
            publicImpact: 5,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),

        // 3. Streetlight Failure — Baekyang-ro
        Issue(
            title: "4 Consecutive Streetlights Out on Baekyang-ro",
            category: .streetlightFailure,
            description: "Four streetlights along Baekyang-ro, between the central library and the science building, have been completely dark for over a week. Students returning from evening classes are unable to see clearly. CCTV camera footage quality in the area has also significantly degraded, raising safety concerns. The affected stretch is approximately 120 meters long and sees heavy pedestrian traffic after 9 PM.",
            latitude: 37.5653,
            longitude: 126.9373,
            supportCount: 31,
            safetyRisk: 4,
            urgency: 5,
            publicImpact: 4,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 4. Drainage Blocked — Hongje-cheon riverside path
        Issue(
            title: "Blocked Storm Drain Causing Flooding on Hongje-cheon Path",
            category: .drainageBlocked,
            description: "The storm drain along the Hongje-cheon riverside walking path near Seodaemun Sports Complex is completely clogged with leaves and debris. During last week's rain, the path flooded to a depth of approximately 10cm, making it impassable for cyclists and joggers. Heavy rainfall is forecast again this week. The blockage spans roughly 3 drain grates and requires immediate clearing.",
            latitude: 37.5712,
            longitude: 126.9441,
            supportCount: 12,
            safetyRisk: 3,
            urgency: 5,
            publicImpact: 3,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 5. Construction Safety Risk — Sinchon redevelopment site
        Issue(
            title: "Unsecured Safety Net at Sinchon Redevelopment Construction Site",
            category: .constructionSafetyRisk,
            description: "A section of the safety netting at the Sinchon redevelopment construction site on Sinchon-ro has detached from the scaffolding, leaving a 5-meter gap. Loose debris including concrete fragments and wire mesh is visible near the opening. The site borders a busy pedestrian walkway used by thousands of people daily. Workers have also been observed operating without proper fall protection equipment at heights above 10 meters.",
            latitude: 37.5548,
            longitude: 126.9362,
            supportCount: 9,
            safetyRisk: 5,
            urgency: 5,
            publicImpact: 4,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 6. Bridge/Infrastructure Risk — Ahyeon overpass
        Issue(
            title: "Severe Railing Corrosion on Ahyeon Overpass",
            category: .bridgeInfraRisk,
            description: "The steel railing on the south side of Ahyeon Overpass shows extensive corrosion at welded joints, with visible rust flaking and a section approximately 2 meters long that wobbles when touched. Concrete cracks on the bridge deck exceed 3mm in width in multiple locations. The overpass was built in the 1980s and may not have received a structural inspection in recent years. Given the high pedestrian volume, immediate inspection is strongly recommended.",
            latitude: 37.5593,
            longitude: 126.9598,
            supportCount: 14,
            safetyRisk: 5,
            urgency: 4,
            publicImpact: 4,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),

        // 7. Road Damage — Completed case near Ewha Womans University
        Issue(
            title: "Large Pothole in Intersection Near Ewha Womans University",
            category: .roadDamage,
            description: "A pothole approximately 40cm in diameter and 8cm deep appeared at the main intersection in front of Ewha Womans University. The damage caused a tire blowout for one vehicle and was reported by multiple residents. Emergency repair was requested given the high vehicle and pedestrian volume at this location.",
            latitude: 37.5617,
            longitude: 126.9468,
            supportCount: 27,
            safetyRisk: 5,
            urgency: 5,
            publicImpact: 5,
            status: .completed,
            reportDate: Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date(),
            completionDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
            completionSummary: "Emergency asphalt repair completed on June 1. A 1.2m x 1.0m section was excavated and filled with hot-mix asphalt. Road surface restored to safe condition. Follow-up inspection scheduled for 3 months.",
            rewardPoints: 55,
            isMyReport: true
        ),

        // 8. Sidewalk Damage — Yonsei University back gate area
        Issue(
            title: "Sunken Sidewalk Near Yonsei University Back Gate",
            category: .sidewalkDamage,
            description: "The sidewalk along Yonhui-ro near Yonsei University's back gate has subsided by approximately 5cm, creating a trip hazard. The area is used by many students and residents accessing the university from the north side. The subsidence appears to be caused by soil erosion beneath the pavement. Several elderly residents have reported near-falls at this location.",
            latitude: 37.5673,
            longitude: 126.9359,
            supportCount: 8,
            safetyRisk: 3,
            urgency: 3,
            publicImpact: 3,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 9. Streetlight Failure — Hongdae area
        Issue(
            title: "Flickering Streetlight Creating Hazard on Wausan-ro",
            category: .streetlightFailure,
            description: "A streetlight on Wausan-ro near Hongik University has been flickering irregularly for two weeks. The intermittent lighting is disorienting for drivers and creates unpredictable shadows for pedestrians crossing the road. The light appears to fail entirely during peak evening hours between 10 PM and midnight, coinciding with the highest foot traffic in the Hongdae entertainment district.",
            latitude: 37.5520,
            longitude: 126.9241,
            supportCount: 16,
            safetyRisk: 3,
            urgency: 4,
            publicImpact: 4,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),

        // 10. Other — Broken public bench near Seodaemun Independence Park
        Issue(
            title: "Broken Bench and Damaged Pavement at Independence Park Entrance",
            category: .other,
            description: "A public bench near the main entrance of Seodaemun Independence Park has a broken seat plank with exposed sharp metal edges. Adjacent to the bench, a section of the paved walkway has heaved upward due to tree root growth, creating a tripping hazard approximately 3cm high. The park is visited by many elderly residents and families with young children, making repairs a priority.",
            latitude: 37.5698,
            longitude: 126.9598,
            supportCount: 6,
            safetyRisk: 2,
            urgency: 2,
            publicImpact: 3,
            status: .received,
            rewardPoints: 10,
            isMyReport: false
        ),

        // 11. Drainage Blocked — Near Seodaemun-gu Office
        Issue(
            title: "Overflowing Manhole Cover on Tongil-ro During Rain",
            category: .drainageBlocked,
            description: "A manhole cover on Tongil-ro in front of Seodaemun-gu Office overflows and becomes partially dislodged during moderate to heavy rainfall events. The condition has been observed during three separate rain events this month. The dislodged cover poses a serious risk to cyclists and motorcyclists. Sewage odor has also been reported by nearby residents and office workers.",
            latitude: 37.5791,
            longitude: 126.9368,
            supportCount: 19,
            safetyRisk: 5,
            urgency: 4,
            publicImpact: 4,
            status: .inProgress,
            rewardPoints: 30,
            isMyReport: false
        ),

        // 12. Construction Safety Risk — Near Yeonhui-dong residential area
        Issue(
            title: "Construction Noise Exceeding Limits in Yeonhui-dong After 10 PM",
            category: .constructionSafetyRisk,
            description: "A residential construction project in Yeonhui-dong has been conducting drilling and pile-driving work after 10 PM on multiple occasions this week, in violation of local noise ordinances. Measured noise levels by a resident reached 78 dB, well above the legal nighttime limit of 50 dB. Multiple households with young children and elderly residents have been unable to sleep. A formal complaint has already been filed with the district office.",
            latitude: 37.5668,
            longitude: 126.9302,
            supportCount: 22,
            safetyRisk: 2,
            urgency: 4,
            publicImpact: 5,
            status: .reviewing,
            rewardPoints: 20,
            isMyReport: false
        ),
    ]
}
