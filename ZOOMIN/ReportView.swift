import SwiftUI
import UIKit
import CoreLocation
import Combine

// ============================================================
//  ReportView.swift
//  멤버 2 — Report Form & Camera (메인 화면)
//
//  책임:
//   - 사진 1장 첨부 (카메라/앨범)  → IssueStore 의 photoData: Data?
//   - 카테고리 선택               → IssueCategory
//   - 위치 (GPS 자동 감지)        → latitude / longitude (필수)
//   - 설명 입력 (0/300)
//   - 우선순위 3요소 입력 (각 1~5): 안전위험 / 긴급도 / 공공영향
//   - 제출 → IssueStore.addIssue(...) 호출
//
//  연동: @EnvironmentObject var store: IssueStore (ContentView 에서 주입)
//  디자인: ZOOMINStyle.swift 컴포넌트/모디파이어 사용
// ============================================================

struct ReportView: View {
    @EnvironmentObject private var store: IssueStore

    // 입력 상태
    @State private var image: UIImage? = nil
    @State private var selectedCategory: IssueCategory? = nil
    @State private var title: String = ""
    @State private var description: String = ""

    // 우선순위 3요소 (각 1~5)
    @State private var safetyRisk: Int = 3
    @State private var urgency: Int = 3
    @State private var publicImpact: Int = 3

    // 위치
    @StateObject private var locationManager = ReportLocationManager()

    // 사진 소스 선택
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showSourceDialog = false

    // 제출 상태
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let maxDescription = 300

    // 유효성: 카테고리 + 제목 + 위치 확보 시 제출 가능
    private var canSubmit: Bool {
        selectedCategory != nil
        && !title.trimmingCharacters(in: .whitespaces).isEmpty
        && locationManager.coordinate != nil
        && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: ZOOMINLayout.paddingLarge) {
                        photoSection
                        titleSection
                        categorySection
                        locationSection
                        descriptionSection
                        prioritySection
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, ZOOMINLayout.paddingMedium)
                }

                // 하단 고정 제출 버튼
                VStack {
                    Spacer()
                    submitButton
                        .padding(.horizontal, ZOOMINLayout.paddingMedium)
                        .padding(.bottom, ZOOMINLayout.paddingSmall)
                        .background(
                            Color.surfaceSecondary.opacity(0.95)
                                .ignoresSafeArea(edges: .bottom)
                        )
                }
            }
            .navigationTitle("Report an Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if isSubmitting { ProgressView() }
                }
            }
            .onAppear { locationManager.request() }
            .confirmationDialog("사진 추가", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button("카메라로 촬영") { showCamera = true }
                Button("앨범에서 선택") { showLibrary = true }
                Button("취소", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { picked in image = picked }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                PhotoLibraryPicker { picked in image = picked }
            }
            .alert("제출 완료", isPresented: $showSuccess) {
                Button("확인", role: .cancel) {}
            } message: {
                Text("제보가 접수되었어요. 함께해 주셔서 감사합니다!")
            }
            .alert("제출 실패", isPresented: .constant(errorMessage != nil)) {
                Button("확인", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: 사진 섹션
    private var photoSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Photo")
            if let image {
                PhotoPreviewView(
                    image: image,
                    onRemove: { self.image = nil },
                    onRetake: { showSourceDialog = true }
                )
            } else {
                PhotoCapturePlaceholder { showSourceDialog = true }
            }
            Text("사진 첨부 시 +5 포인트")
                .font(ZOOMINFont.micro)
                .foregroundColor(.textTertiary)
        }
    }

    // MARK: 제목 섹션
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Title")
            TextField("제목을 입력하세요", text: $title)
                .font(ZOOMINFont.body)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                .frame(height: 52)
                .background(Color.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                        .stroke(Color.surfaceTertiary, lineWidth: 1)
                )
        }
    }

    // MARK: 카테고리 섹션
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Category")
            Menu {
                ForEach(IssueCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.displayName, systemImage: category.symbolName)
                    }
                }
            } label: {
                HStack {
                    if let category = selectedCategory {
                        Image(systemName: category.symbolName)
                            .foregroundColor(category.markerColor)
                        Text(category.displayName)
                            .font(ZOOMINFont.body)
                            .foregroundColor(.textPrimary)
                    } else {
                        Text("Select category")
                            .font(ZOOMINFont.body)
                            .foregroundColor(.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.zoominBlue)
                }
                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                .frame(height: 52)
                .background(Color.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                        .stroke(selectedCategory != nil ? Color.zoominBlue : Color.surfaceTertiary,
                                lineWidth: selectedCategory != nil ? 1.5 : 1)
                )
            }
        }
    }

    // MARK: 위치 섹션 (GPS 자동 감지)
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Location")
            HStack {
                Text(locationManager.statusText)
                    .font(ZOOMINFont.body)
                    .foregroundColor(locationManager.coordinate != nil ? .textPrimary : .textTertiary)
                Spacer()
                if locationManager.coordinate == nil {
                    Button("재시도") { locationManager.request() }
                        .font(ZOOMINFont.captionBold)
                        .foregroundColor(.zoominBlue)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundColor(.zoominBlue)
                }
            }
            .padding(.horizontal, ZOOMINLayout.paddingMedium)
            .frame(height: 52)
            .background(Color.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
        }
    }

    // MARK: 설명 섹션 (0/300)
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Description")
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("문제를 설명해주세요...")
                        .font(ZOOMINFont.body)
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, ZOOMINLayout.paddingMedium)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $description)
                    .font(ZOOMINFont.body)
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, ZOOMINLayout.paddingMedium - 4)
                    .padding(.vertical, 8)
                    .frame(height: 120)
                    .onChange(of: description) { _, newValue in
                        if newValue.count > maxDescription {
                            description = String(newValue.prefix(maxDescription))
                        }
                    }
            }
            .background(Color.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium)
                    .stroke(Color.surfaceTertiary, lineWidth: 1)
            )

            HStack {
                Spacer()
                Text("\(description.count)/\(maxDescription)")
                    .font(ZOOMINFont.micro)
                    .foregroundColor(.textTertiary)
            }
        }
    }

    // MARK: 우선순위 3요소 섹션
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingMedium) {
            sectionLabel("위험도 평가")
            priorityRow(title: "안전 위험도", systemImage: "exclamationmark.shield.fill", value: $safetyRisk)
            priorityRow(title: "긴급도", systemImage: "clock.fill", value: $urgency)
            priorityRow(title: "공공 영향도", systemImage: "person.3.fill", value: $publicImpact)

            // 예상 우선순위 점수 미리보기 (지지점수 0 가정)
            let preview = safetyRisk + urgency + publicImpact
            HStack {
                Text("예상 우선순위")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(preview) / 15")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.zoominBlue)
            }
        }
        .zoominCard()
    }

    private func priorityRow(title: String, systemImage: String, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13))
                    .foregroundColor(.zoominBlue)
                Text(title)
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(ZOOMINFont.captionBold)
                    .foregroundColor(.zoominBlue)
            }
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.easeInOut(duration: 0.12)) { value.wrappedValue = level }
                    } label: {
                        Text("\(level)")
                            .font(ZOOMINFont.captionBold)
                            .foregroundColor(value.wrappedValue >= level ? .white : .textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(value.wrappedValue >= level ? levelColor(level) : Color.surfaceTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))
                    }
                }
            }
        }
    }

    private func levelColor(_ level: Int) -> Color {
        switch level {
        case 1: return .riskLow
        case 2: return .riskLow
        case 3: return .riskMedium
        case 4: return .riskHigh
        default: return .riskCritical
        }
    }

    // MARK: 제출 버튼
    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Text(isSubmitting ? "Submitting..." : "Submit Report")
        }
        .zoominPrimaryButton()
        .opacity(canSubmit ? 1.0 : 0.5)
        .disabled(!canSubmit)
    }

    // MARK: - 헬퍼
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(ZOOMINFont.title3)
            .foregroundColor(.textPrimary)
    }

    private func submit() {
        guard let category = selectedCategory,
              let coordinate = locationManager.coordinate else { return }

        isSubmitting = true

        let photoData = image?.jpegDataForUpload()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // 공용 스토어에 추가 (메인 스레드)
        store.addIssue(
            title: trimmedTitle,
            category: category,
            description: description,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            photoData: photoData,
            safetyRisk: safetyRisk,
            urgency: urgency,
            publicImpact: publicImpact
        )

        isSubmitting = false
        resetForm()
        showSuccess = true
    }

    private func resetForm() {
        image = nil
        selectedCategory = nil
        title = ""
        description = ""
        safetyRisk = 3
        urgency = 3
        publicImpact = 3
    }
}

// ============================================================
//  ReportLocationManager
//  제보 위치 자동 감지. 권한 요청 + 1회 위치 획득.
//  ⚠️ Info.plist 에 NSLocationWhenInUseUsageDescription 필요.
// ============================================================
final class ReportLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var statusText: String = "위치 확인 중..."

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        statusText = "위치 확인 중..."
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            statusText = "위치 권한이 필요합니다 (설정에서 허용)"
        @unknown default:
            statusText = "위치를 가져올 수 없습니다"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            statusText = "위치 권한이 필요합니다 (설정에서 허용)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        statusText = String(format: "위치 감지됨 (%.5f, %.5f)", loc.coordinate.latitude, loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusText = "위치를 가져올 수 없습니다"
    }
}

// MARK: - 프리뷰
#Preview {
    ReportView()
        .environmentObject(IssueStore())
}
