// ContentView.swift
// ZOOMIN — Member 1
// Role: 4-tab TabView entry point + IssueStore EnvironmentObject injection
// Design: Based on ZOOMINStyle.swift, zoominBlue accent

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

// MARK: - Role-based TabView

struct MainTabView: View {

    @EnvironmentObject var session: AppSession
    @EnvironmentObject var issueStore: IssueStore

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Tab 1: Map (common) ──────────────────────────────────────
            MapView()
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(0)

            // ── Tab 2: Report (residents only) ──────────────────────────
            if session.userRole == .resident {
                ReportView()
                    .tabItem { Label("Report", systemImage: "camera.fill") }
                    .tag(1)

                // ── Tab 3: My Issues (residents only) ───────────────────────
                MyIssuesView()
                    .tabItem { Label("My Issues", systemImage: "list.bullet.rectangle.fill") }
                    .tag(2)
            }

            // ── Tab 3/2: Admin Dashboard (admins only) ────────────────────
            if session.userRole == .admin {
                AdminDashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                    .tag(1)
            }

            // ── Last Tab: Profile / Logout (common) ───────────────────
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(9)
        }
        .tint(session.userRole == .admin ? Color.riskHigh : Color.zoominBlue)
    }
}

// MARK: - Profile / Logout View

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

                        // Profile card
                        profileCard

                        // Role info
                        roleInfoCard

                        // Logout button
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

    // Profile card
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

    // Role info card
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

    // Logout button
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

// MARK: - Feature Row

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

