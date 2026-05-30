// ContentView.swift
// ZOOMIN — Member 1 담당
// 역할: 4탭 TabView 진입점 + IssueStore EnvironmentObject 주입
// 디자인: ZOOMINStyle.swift 기반, zoominBlue 강조

import SwiftUI

struct ContentView: View {

    // MARK: - App-wide 상태 (한 번만 생성, 모든 탭에 공유)
    @StateObject private var issueStore = IssueStore()

    @State private var selectedTab: Int = 0

    // MARK: - 탭 정의
    private enum Tab: Int, CaseIterable {
        case map      = 0
        case report   = 1
        case myIssues = 2
        case admin    = 3

        var title: String {
            switch self {
            case .map:      return "Map"
            case .report:   return "Report"
            case .myIssues: return "My Issues"
            case .admin:    return "Admin"
            }
        }

        var icon: String {
            switch self {
            case .map:      return "map.fill"
            case .report:   return "camera.fill"
            case .myIssues: return "list.bullet.rectangle.fill"
            case .admin:    return "person.badge.shield.checkmark.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── 탭 1: 지도 (Member 1 담당) ──────────────────────────────
            MapView()
                .tabItem { Label(Tab.map.title, systemImage: Tab.map.icon) }
                .tag(Tab.map.rawValue)

            // ── 탭 2: 신고하기 (Member 2 담당) ──────────────────────────
            ReportView()
                .tabItem { Label(Tab.report.title, systemImage: Tab.report.icon) }
                .tag(Tab.report.rawValue)

            // ── 탭 3: 내 신고 (Member 4 담당) ───────────────────────────
            MyIssuesPlaceholderView()
                .tabItem { Label(Tab.myIssues.title, systemImage: Tab.myIssues.icon) }
                .tag(Tab.myIssues.rawValue)

            // ── 탭 4: 관리자 (Member 4 담당) ────────────────────────────
            AdminPlaceholderView()
                .tabItem { Label(Tab.admin.title, systemImage: Tab.admin.icon) }
                .tag(Tab.admin.rawValue)
        }
        // ✅ IssueStore를 모든 하위 뷰에 주입
        .environmentObject(issueStore)
        .tint(Color.zoominBlue)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

// MARK: - Placeholder Views
// ⚠️ 팀원 파일이 완성되면 아래를 실제 View로 교체하세요.

private struct ReportPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.surfaceSecondary.ignoresSafeArea()
            ZOOMINEmptyStateView(
                mood: .default,
                title: "Report Screen",
                message: "Member 2 담당\nReportView.swift + CameraPicker.swift"
            )
        }
    }
}

private struct MyIssuesPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.surfaceSecondary.ignoresSafeArea()
            ZOOMINEmptyStateView(
                mood: .search,
                title: "My Issues",
                message: "Member 4 담당\nMyIssuesView.swift"
            )
        }
    }
}

private struct AdminPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.surfaceSecondary.ignoresSafeArea()
            ZOOMINEmptyStateView(
                mood: .working,
                title: "Admin Dashboard",
                message: "Member 4 담당\nAdminDashboardView.swift"
            )
        }
    }
}
