// ContentView.swift
// ZOOMIN — Member 1 담당
// 역할: 4탭 TabView 진입점 + IssueStore EnvironmentObject 주입
// 디자인: ZOOMINStyle.swift 기반, zoominBlue 강조

// ContentView.swift
// ZOOMIN — Member 1 (Member 4 added Login / Role separation)
// Role: Login → Role-based TabView entry point

import SwiftUI
import Combine

struct ContentView: View {

    @StateObject private var issueStore = IssueStore()
    @StateObject private var session    = AppSession()

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainTabView()
                    .environmentObject(issueStore)
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
    }
}

// MARK: - 역할별 탭뷰

struct MainTabView: View {

    @EnvironmentObject var session: AppSession
    @EnvironmentObject var issueStore: IssueStore

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── 탭 1: 지도 (공통) ──────────────────────────────────────
            MapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(0)

            // ── 탭 2: 신고하기 (일반 주민만) ──────────────────────────
            if session.userRole == .resident {
                ReportView()
                    .tabItem { Label("Report", systemImage: "camera.fill") }
                    .tag(1)

                // ── 탭 3: 내 신고 (일반 주민만) ───────────────────────
                MyIssuesView()
                    .tabItem { Label("My Issues", systemImage: "list.bullet.rectangle.fill") }
                    .tag(2)
            }

            // ── 탭 3/2: 관리자 대시보드 (관리자만) ────────────────────
            if session.userRole == .admin {
                AdminDashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                    .tag(1)
            }

            // ── 탭 마지막: 내 정보/로그아웃 (공통) ───────────────────
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(9)
        }
        .tint(session.userRole == .admin ? Color.riskHigh : Color.zoominBlue)
    }
}

// MARK: - 프로필 / 로그아웃 뷰

struct ProfileView: View {

    @EnvironmentObject var session: AppSession
    @EnvironmentObject var issueStore: IssueStore
    @State private var showLogoutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: ZOOMINLayout.paddingMedium) {

                        // 프로필 카드
                        profileCard

                        // 역할 정보
                        roleInfoCard

                        // 로그아웃 버튼
                        logoutButton
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Are you sure you want to log out?", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) { session.logout() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // 프로필 카드
    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(session.userRole == .admin
                          ? Color.riskHigh.opacity(0.15)
                          : Color.zoominBlue.opacity(0.15))
                    .frame(width: 64, height: 64)
                Image(systemName: session.userRole == .admin
                      ? "person.badge.shield.checkmark.fill"
                      : "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(session.userRole == .admin ? .riskHigh : .zoominBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.userName)
                    .font(ZOOMINFont.title2)
                    .foregroundColor(.textPrimary)
                Text(session.userRole == .admin ? "Admin" : "Resident")
                    .font(ZOOMINFont.caption)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .zoominCard()
    }

    // 역할 정보 카드
    private var roleInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Features")
                .font(ZOOMINFont.title3)
                .foregroundColor(.textPrimary)

            if session.userRole == .resident {
                FeatureRow(icon: "map.fill",        label: "View reports on map",   color: .zoominBlue)
                FeatureRow(icon: "camera.fill",     label: "Submit a report",      color: .zoominBlue)
                FeatureRow(icon: "list.bullet.rectangle.fill", label: "My reports · Points", color: .zoominBlue)
            } else {
                FeatureRow(icon: "map.fill",                   label: "View reports on map",    color: .riskHigh)
                FeatureRow(icon: "chart.bar.fill",             label: "Report dashboard",         color: .riskHigh)
                FeatureRow(icon: "checkmark.seal.fill",        label: "Update status · Completion report", color: .riskHigh)
            }
        }
        .zoominCard()
    }

    // 로그아웃 버튼
    private var logoutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .font(ZOOMINFont.bodyBold)
            }
            .foregroundColor(.riskCritical)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.riskCritical.opacity(0.08))
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                    .stroke(Color.riskCritical.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

// MARK: - 기능 소개 행

private struct FeatureRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            Text(label)
                .font(ZOOMINFont.body)
                .foregroundColor(.textPrimary)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

