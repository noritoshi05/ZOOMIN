// LoginView.swift
// ZOOMIN — Member 4
// Role: Login screen / User role separation (Resident vs Admin)

import SwiftUI
import Combine

// MARK: - User Role

enum UserRole {
    case resident   // General resident
    case admin      // Administrator
}

// MARK: - App Session Manager

class AppSession: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userRole: UserRole = .resident
    @Published var userName: String = ""

    func login(name: String, role: UserRole) {
        userName = name
        userRole = role
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = true
        }
    }

    func logout() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoggedIn = false
        }
        userName = ""
        userRole = .resident
    }
}

// MARK: - LoginView

struct LoginView: View {

    @EnvironmentObject var session: AppSession

    @State private var name: String = ""
    @State private var selectedRole: UserRole = .resident
    @State private var adminCode: String = ""
    @State private var showWrongCode: Bool = false
    @State private var isAnimating: Bool = false

    // 간단한 관리자 코드 (실제 앱에선 서버 인증)
    private let correctAdminCode = "ZOOMIN2026"

    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [Color.zoominBlue.opacity(0.08), Color.surfaceSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // 1. 로고 헤더
                    logoSection

                    // 2. 역할 선택
                    roleSelectorSection
                        .padding(.top, 32)

                    // 3. 이름 입력
                    nameSection
                        .padding(.top, 20)

                    // 4. 관리자 코드 (관리자 선택 시만)
                    if selectedRole == .admin {
                        adminCodeSection
                            .padding(.top, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // 5. 로그인 버튼
                    loginButton
                        .padding(.top, 28)

                    // 6. 하단 안내
                    footerNote
                        .padding(.top, 16)
                }
                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedRole)
    }

    // MARK: - 로고 섹션

    private var logoSection: some View {
        VStack(spacing: 12) {
            // 앱 아이콘
            ZStack {
                Circle()
                    .fill(Color.zoominBlue)
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.zoominBlue.opacity(0.35), radius: 16, x: 0, y: 8)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }

            Text("ZOOMIN")
                .font(ZOOMINFont.largeTitle)
                .foregroundColor(.textPrimary)

            Text("Urban Infrastructure Report Platform")
                .font(ZOOMINFont.caption)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - 역할 선택 섹션

    private var roleSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Login Type")
                .font(ZOOMINFont.captionBold)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                RoleCard(
                    icon: "person.fill",
                    title: "Resident",
                    subtitle: "Report · Map · Points",
                    isSelected: selectedRole == .resident,
                    color: .zoominBlue
                ) {
                    withAnimation { selectedRole = .resident }
                }

                RoleCard(
                    icon: "person.badge.shield.checkmark.fill",
                    title: "Admin",
                    subtitle: "Manage Reports · Update Status",
                    isSelected: selectedRole == .admin,
                    color: .riskHigh
                ) {
                    withAnimation { selectedRole = .admin }
                }
            }
        }
    }

    // MARK: - 이름 입력 섹션

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(selectedRole == .admin ? "Admin Name" : "Nickname")
                .font(ZOOMINFont.captionBold)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundColor(.zoominBlue)
                    .font(.system(size: 16))
                TextField(
                    selectedRole == .admin ? "Enter admin name" : "Enter nickname",
                    text: $name
                )
                .font(ZOOMINFont.body)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
            }
            .padding(ZOOMINLayout.paddingMedium)
            .background(Color.surfacePrimary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .stroke(Color.zoominBlue.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - 관리자 코드 섹션

    private var adminCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Admin Code")
                .font(ZOOMINFont.captionBold)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.riskHigh)
                    .font(.system(size: 16))
                SecureField("Enter admin code", text: $adminCode)
                    .font(ZOOMINFont.body)
                    .foregroundColor(.textPrimary)
                    .autocorrectionDisabled()
            }
            .padding(ZOOMINLayout.paddingMedium)
            .background(Color.surfacePrimary)
            .cornerRadius(ZOOMINLayout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .stroke(
                        showWrongCode ? Color.riskCritical.opacity(0.6) : Color.riskHigh.opacity(0.3),
                        lineWidth: showWrongCode ? 1.5 : 1
                    )
            )

            if showWrongCode {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                    Text("Invalid admin code")
                        .font(ZOOMINFont.micro)
                }
                .foregroundColor(.riskCritical)
                .padding(.horizontal, 4)
            }

            // 힌트
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                Text("Contact your team leader for the admin code")
                    .font(ZOOMINFont.micro)
            }
            .foregroundColor(.textTertiary)
            .padding(.horizontal, 4)
        }
    }

    // MARK: - 로그인 버튼

    private var loginButton: some View {
        Button {
            handleLogin()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selectedRole == .admin
                      ? "person.badge.shield.checkmark.fill"
                      : "person.fill")
                Text(selectedRole == .admin ? "Start as Admin" : "Start as Resident")
                    .font(ZOOMINFont.bodyBold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                selectedRole == .admin
                ? Color.riskHigh
                : Color.zoominBlue
            )
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .shadow(
                color: (selectedRole == .admin ? Color.riskHigh : Color.zoominBlue).opacity(0.3),
                radius: 8, x: 0, y: 4
            )
        }
        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - 하단 안내

    private var footerNote: some View {
        Text("This app is a team project prototype")
            .font(ZOOMINFont.micro)
            .foregroundColor(.textTertiary)
    }

    // MARK: - 로그인 처리

    private func handleLogin() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if selectedRole == .admin {
            if adminCode == correctAdminCode {
                showWrongCode = false
                session.login(name: trimmedName, role: .admin)
            } else {
                withAnimation { showWrongCode = true }
            }
        } else {
            session.login(name: trimmedName, role: .resident)
        }
    }
}

// MARK: - 역할 카드

private struct RoleCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : Color.surfaceTertiary)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .textTertiary)
                }

                VStack(spacing: 3) {
                    Text(title)
                        .font(ZOOMINFont.bodyBold)
                        .foregroundColor(isSelected ? color : .textSecondary)
                    Text(subtitle)
                        .font(ZOOMINFont.micro)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? color.opacity(0.08) : Color.surfacePrimary)
            .cornerRadius(ZOOMINLayout.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                    .stroke(
                        isSelected ? color.opacity(0.5) : Color.textTertiary.opacity(0.2),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AppSession())
}
