import SwiftUI
import UIKit
import CoreLocation
import Combine

// ============================================================
//  ReportView.swift
//  Member 2 — Report Form & Camera (Main screen)
//
//  Responsibilities:
//   - Attach 1 photo (camera/album) → photoData: Data? in IssueStore
//   - Select category → IssueCategory
//   - Location (auto GPS) → latitude / longitude (required)
//   - Description input (0/300)
//   - Priority 3 factors (each 1~5): Safety Risk / Urgency / Public Impact
//   - Submit → calls IssueStore.addIssue(...)
//
//  Integration: @EnvironmentObject var store: IssueStore (injected from ContentView)
//  Design: Uses ZOOMINStyle.swift components/modifiers
// ============================================================

struct ReportView: View {
    @EnvironmentObject private var store: IssueStore

    // Input state
    @State private var image: UIImage? = nil
    @State private var selectedCategory: IssueCategory? = nil
    @State private var title: String = ""
    @State private var description: String = ""

    // Priority 3 factors (each 1~5)
    @State private var safetyRisk: Int = 3
    @State private var urgency: Int = 3
    @State private var publicImpact: Int = 3

    // Location
    @StateObject private var locationManager = ReportLocationManager()

    // Photo source selection
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var showSourceDialog = false

    // Submission state
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private let maxDescription = 300

    // Validation: submittable when category + title + location are set
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

                // Fixed bottom submit button
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        resetForm()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Reset")
                                .font(ZOOMINFont.caption)
                        }
                        .foregroundColor(.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSubmitting { ProgressView() }
                }
            }
            .onAppear { locationManager.request() }
            .confirmationDialog("Add Photo", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { picked in image = picked }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showLibrary) {
                PhotoLibraryPicker { picked in image = picked }
            }
            .alert("Submitted!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your report has been received. Thank you for your contribution!")
            }
            .alert("Submission Failed", isPresented: .constant(errorMessage != nil)) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: Photo Section
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
            Text("+5 points for attaching a photo")
                .font(ZOOMINFont.micro)
                .foregroundColor(.textTertiary)
        }
    }

    // MARK: Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Title")
            TextField("Enter title", text: $title)
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

    // MARK: Category Section
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

    // MARK: Location Section (Auto GPS)
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Location")
            HStack {
                Text(locationManager.statusText)
                    .font(ZOOMINFont.body)
                    .foregroundColor(locationManager.coordinate != nil ? .textPrimary : .textTertiary)
                Spacer()
                if locationManager.coordinate == nil {
                    Button("Retry") { locationManager.request() }
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

    // MARK: Description Section (0/300)
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingSmall) {
            sectionLabel("Description")
            ZStack(alignment: .topLeading) {
                if description.isEmpty {
                    Text("Describe the issue...")
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

    // MARK: Priority Factors Section
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: ZOOMINLayout.paddingMedium) {
            sectionLabel("Risk Assessment")
            priorityRow(title: "Safety Risk", systemImage: "exclamationmark.shield.fill", value: $safetyRisk)
            priorityRow(title: "Urgency", systemImage: "clock.fill", value: $urgency)
            priorityRow(title: "Public Impact", systemImage: "person.3.fill", value: $publicImpact)

            // Estimated priority score preview (support score assumed 0)
            let preview = safetyRisk + urgency + publicImpact
            HStack {
                Text("Estimated Priority")
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

    // MARK: Submit Button
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

    // MARK: - Helpers
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

        // Add to shared store (main thread)
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
//  Auto-detects report location. Requests permission + obtains location once.
//  ⚠️ NSLocationWhenInUseUsageDescription required in Info.plist.
// ============================================================
final class ReportLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var statusText: String = "Detecting location..."

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        statusText = "Detecting location..."
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            statusText = "Location permission required (enable in Settings)"
        @unknown default:
            statusText = "Unable to get location"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.requestLocation()
        } else if status == .denied || status == .restricted {
            statusText = "Location permission required (enable in Settings)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        coordinate = loc.coordinate
        statusText = String(format: "Location detected (%.5f, %.5f)", loc.coordinate.latitude, loc.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusText = "Unable to get location"
    }
}

// MARK: - Preview
#Preview {
    ReportView()
        .environmentObject(IssueStore())
}


