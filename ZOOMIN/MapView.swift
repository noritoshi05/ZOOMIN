// MapView.swift
// ZOOMIN — Member 1
// Role: Map screen / Report markers / Bottom Nearby Issues card / IssueDetailView navigation
// Design: Full ZOOMINStyle applied / Urban infrastructure management platform

import SwiftUI
import MapKit

// MARK: - MapView

struct MapView: View {

    @EnvironmentObject var issueStore: IssueStore

    // Map camera (Seoul center default)
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    )

    @State private var selectedIssue: Issue? = nil
    @State private var selectedIssueID: UUID? = nil
    @State private var showFilter: Bool = false
    @State private var filterCategory: IssueCategory? = nil
    @State private var showNearbySheet: Bool = false
    @State private var showSearch: Bool = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {

                // ── Map body───────────────────────────────────────────
                mapBody
                    .ignoresSafeArea(edges: .top)

                // ── Bottom-right location button─────────────────────────────────
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        locationButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 220) // Above Nearby panel height
                    }
                }

                // ── Bottom Nearby Issues panel─────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    nearbyIssuesPanel
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .navigationDestination(item: $selectedIssue) { issue in
                IssueDetailView(issue: issue)
            }
            .sheet(isPresented: $showFilter) {
                CategoryFilterSheet(selectedCategory: $filterCategory)
            }
            .sheet(isPresented: $showSearch) {
                IssueSearchSheet(
                    searchText: $searchText,
                    onSelect: { issue in
                        showSearch = false
                        selectedIssueID = issue.id
                        withAnimation(.easeInOut(duration: 0.5)) {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: issue.latitude,
                                        longitude: issue.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                                )
                            )
                        }
                    }
                )
            }
        }
    }

    // MARK: - Map Body

    private var mapBody: some View {
        Map(position: $cameraPosition, interactionModes: .all, selection: $selectedIssueID) {
            ForEach(filteredIssues) { issue in
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: issue.latitude,
                        longitude: issue.longitude
                    ),
                    anchor: .bottom
                ) {
                    IssueMapMarker(issue: issue, isSelected: selectedIssueID == issue.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                                selectedIssueID = issue.id
                                selectedIssue = issue
                            }
                        }
                }
                .tag(issue.id)
            }
        }
        .mapStyle(.standard(elevation: .flat,
                            pointsOfInterest: .including([.publicTransport, .hospital])))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Bottom Nearby Issues Panel

    private var nearbyIssuesPanel: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearby Issues")
                        .font(ZOOMINFont.title3)
                        .foregroundStyle(Color.textPrimary)
                    Text("Road · Sidewalk · Facility Reports")
                        .font(ZOOMINFont.micro)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                // Stat chips
                statsRow
                Button("View All") {
                    showNearbySheet = true
                }
                .font(ZOOMINFont.captionBold)
                .foregroundStyle(Color.zoominBlue)
                .padding(.leading, 8)
            }
            .padding(.horizontal, ZOOMINLayout.paddingMedium)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Horizontal scroll issue card list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(issueStore.sortedByPriority.prefix(8)) { issue in
                        NearbyIssueCard(
                            issue: issue,
                            isSelected: selectedIssueID == issue.id,
                            onTap: {
                                // Card tap: map move + marker select only (no detail navigation)
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedIssueID = issue.id
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(
                                                latitude: issue.latitude,
                                                longitude: issue.longitude
                                            ),
                                            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                                        )
                                    )
                                }
                            },
                            onDetailTap: {
                                // ">" button tap: navigate to detail screen
                                selectedIssue = issue
                            }
                        )
                    }
                }
                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                .padding(.bottom, 14)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusXL))
        .shadow(color: .black.opacity(0.10), radius: 16, y: -4)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        // Full list sheet
        .sheet(isPresented: $showNearbySheet) {
            AllIssuesSheet()
        }
    }

    // Brief stat chip (high risk count)
    private var statsRow: some View {
        let highCount = filteredIssues.filter { $0.priorityLevel == .high }.count
        return HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.riskCritical)
            Text("High \(highCount)")
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.riskCritical)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.riskCritical.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Center ZOOMIN title
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Color.zoominBlue)
                Text("ZOOMIN")
                    .font(ZOOMINFont.title1)
                    .foregroundStyle(Color.zoominBlue)
            }
        }

        // Left: Category filter
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showFilter.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: filterCategory == nil
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                    if let cat = filterCategory {
                        Text(cat.displayName)
                            .font(ZOOMINFont.micro)
                    }
                }
                .foregroundStyle(filterCategory == nil ? Color.textSecondary : Color.zoominBlue)
            }
        }

        // Right: Search
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.zoominBlue)
            }
        }
    }

    // MARK: - My Location Button

    private var locationButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                // Simulator: reset to Seoul center / Real device: move to actual GPS location
                cameraPosition = .userLocation(fallback: .region(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                        span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                    )
                ))
            }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.zoominBlue)
                .frame(width: 44, height: 44)
                .background(Color.surfacePrimary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        }
    }

    // MARK: - Helpers

    private var filteredIssues: [Issue] {
        guard let cat = filterCategory else { return issueStore.issues }
        return issueStore.issues.filter { $0.category == cat }
    }
}

// MARK: - Map Marker

struct IssueMapMarker: View {
    let issue: Issue
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer ring pulse when selected
                if isSelected {
                    Circle()
                        .fill(issue.category.markerColor.opacity(0.20))
                        .frame(width: 52, height: 52)
                }

                // Main circular marker
                Circle()
                    .fill(issue.category.markerColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: issue.category.markerColor.opacity(0.5),
                            radius: isSelected ? 8 : 3)
                    .overlay {
                        Image(systemName: issue.category.symbolName)
                            .font(.system(size: isSelected ? 17 : 13, weight: .bold))
                            .foregroundStyle(.white)
                    }

                // High priority: red badge top-right
                if issue.priorityLevel == .high && !isSelected {
                    Circle()
                        .fill(Color.riskCritical)
                        .frame(width: 10, height: 10)
                        .offset(x: 12, y: -12)
                }
            }

            // Marker tail
            MarkerTail(color: issue.category.markerColor)

            // Score badge popup when selected
            if isSelected {
                selectedBadge
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    private var selectedBadge: some View {
        VStack(spacing: 2) {
            Text(issue.title)
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)
            HStack(spacing: 4) {
                ZOOMINRiskBadge(level: issue.safetyRisk)
                Text("Score \(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))")
                    .font(ZOOMINFont.micro)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .offset(y: 6)
    }
}

private struct MarkerTail: View {
    let color: Color
    var body: some View {
        Triangle()
            .fill(color)
            .frame(width: 10, height: 6)
            .offset(y: -1)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Nearby Issue Horizontal Scroll Card

struct NearbyIssueCard: View {
    let issue: Issue
    var isSelected: Bool = false
    var onTap: () -> Void = {}        // Card tap: map move
    var onDetailTap: () -> Void = {}  // ">" button: detail screen

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12))
                    .frame(width: 56, height: 56)

                if let uiImg = issue.uiImage {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))
                } else {
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(issue.category.markerColor)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title)
                    .font(ZOOMINFont.captionBold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)

                Text("2.3 km away")
                    .font(ZOOMINFont.micro)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 6) {
                    ZOOMINStatusBadge(status: issue.status)
                    ZOOMINRiskBadge(level: issue.safetyRisk)
                }
            }

            // ✅ Detail screen button (separate from map move)
            Button {
                onDetailTap()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.zoominBlue : Color.textTertiary)
                    .padding(8)
                    .background(isSelected ? Color.zoominBlueLight : Color.clear)
                    .clipShape(Circle())
            }
        }
        // ✅ Full card tap → map move only
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .zoominCard(padding: 12)
        .frame(width: 270)
        // Selected card border highlight
        .overlay(
            RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                .stroke(isSelected ? Color.zoominBlue : Color.clear, lineWidth: 1.5)
        )
        // High priority card: left accent bar
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.riskCritical)
                    .frame(width: 3)
                    .padding(.vertical, 10)
                    .offset(x: -ZOOMINLayout.paddingMedium + 3)
            }
        }
    }
}

// MARK: - Category Filter Sheet

struct CategoryFilterSheet: View {
    @Binding var selectedCategory: IssueCategory?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    filterRow(
                        icon: "map.fill",
                        color: Color.zoominBlue,
                        title: "View All",
                        isSelected: selectedCategory == nil
                    )
                }

                ForEach(IssueCategory.allCases, id: \.self) { cat in
                    Button {
                        selectedCategory = cat
                        dismiss()
                    } label: {
                        filterRow(
                            icon: cat.symbolName,
                            color: cat.markerColor,
                            title: cat.displayName,
                            isSelected: selectedCategory == cat
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Category Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.zoominBlue)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func filterRow(icon: String, color: Color, title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 26)
            Text(title)
                .font(ZOOMINFont.body)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.zoominBlue)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}

// MARK: - Full Issue List Sheet

struct AllIssuesSheet: View {
    @EnvironmentObject var issueStore: IssueStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                if issueStore.issues.isEmpty {
                    ZOOMINEmptyStateView(
                        mood: .search,
                        title: "No Reports",
                        message: "No urban facility reports have been submitted yet."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Top summary card
                            summaryCard
                                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                                .padding(.top, 12)

                            ForEach(issueStore.sortedByPriority) { issue in
                                AllIssueRow(issue: issue)
                                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("All Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.zoominBlue)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // Top platform stats card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Urban Maintenance Dashboard")
                        .font(ZOOMINFont.captionBold)
                        .foregroundStyle(Color.zoominBlue)
                    Text("도로·보도·건설 안전 위험 신고 현황")
                        .font(ZOOMINFont.micro)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                PingoView(mood: .working, size: 44)
            }

            HStack(spacing: 0) {
                statChip(value: issueStore.issues.count,        label: "전체", color: Color.zoominBlue)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: highRiskCount,                  label: "高위험", color: Color.riskCritical)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: inProgressCount,                label: "처리중", color: Color.statusInProgress)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: completedCount,                 label: "완료", color: Color.statusCompleted)
            }
        }
        .zoominCard()
    }

    private func statChip(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(ZOOMINFont.title2)
                .foregroundStyle(color)
            Text(label)
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var highRiskCount: Int {
        issueStore.issues.filter { $0.priorityLevel == .high }.count
    }
    private var inProgressCount: Int {
        issueStore.issues.filter { $0.status == .inProgress }.count
    }
    private var completedCount: Int {
        issueStore.issues.filter { $0.status == .completed }.count
    }
}

// MARK: - 전체 목록 행 카드

private struct AllIssueRow: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12))
                    .frame(width: 60, height: 60)

                if let uiImg = issue.uiImage {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))
                } else {
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(issue.category.markerColor)
                }
            }

            // 중앙 정보
            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title)
                    .font(ZOOMINFont.bodyBold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text("Main St · 2.3 km away")
                    .font(ZOOMINFont.micro)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 6) {
                    ZOOMINStatusBadge(status: issue.status)
                }

                ZOOMINPriorityBar(score: Double(issue.priorityScore))
                    .frame(width: 160)
            }

            Spacer()

            // 우측 점수
            VStack(spacing: 4) {
                Text(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))
                    .font(ZOOMINFont.title2)
                    .foregroundStyle(scoreColor)
                Text("Score")
                    .font(ZOOMINFont.micro)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .zoominCard(padding: 12)
        // High 우선순위 강조 바
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.riskCritical)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
        }
    }

    private var scoreColor: Color {
        switch issue.priorityLevel {
        case .high:   return .riskCritical
        case .medium: return .riskHigh
        case .low:    return .riskLow
        }
    }
}

// MARK: - IssueDetailView (Member 3 완성 전 임시)
// ⚠️ Member 3 IssueDetailView.swift 완성 후 이 파일 전체 삭제 후 교체

struct IssueDetailView: View {
    let issue: Issue
    @EnvironmentObject var issueStore: IssueStore
    @State private var selectedTab: Int = 0

    private let detailTabs = ["Details", "Updates", "Comments"]

    var body: some View {
        ZStack {
            Color.surfaceSecondary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 상단 사진 영역
                    photoHeader

                    // Info 영역
                    VStack(spacing: 12) {
                        infoCard
                        priorityCard
                        supportSection
                        tabSection
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // 사진 헤더 (240pt)
    private var photoHeader: some View {
        ZStack(alignment: .topLeading) {
            if let uiImg = issue.uiImage {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 240)
                    .clipped()
            } else {
                ZStack {
                    issue.category.markerColor.opacity(0.10)
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(issue.category.markerColor.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
            }

            // 좌상단 카테고리 배지 오버레이
            HStack(spacing: 6) {
                Image(systemName: issue.category.symbolName)
                    .font(.system(size: 12, weight: .semibold))
                Text(issue.category.displayName)
                    .font(ZOOMINFont.captionBold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(issue.category.markerColor)
            .clipShape(Capsule())
            .padding(16)

            // 우상단 공유 버튼
            HStack {
                Spacer()
                Button {
                    // 공유 기능 (향후 확장)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(16)
            }
        }
    }

    // 기본 정보 카드
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(issue.title)
                .font(ZOOMINFont.title2)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                Text("Main St · 2.3 km away · Reported \(issue.reportDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(ZOOMINFont.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 8) {
                ZOOMINStatusBadge(status: issue.status)
                ZOOMINRiskBadge(level: issue.safetyRisk)
            }

            if !issue.description.isEmpty {
                Divider()
                Text(issue.description)
                    .font(ZOOMINFont.body)
                    .foregroundStyle(Color.textSecondary)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zoominCard()
    }

    // 우선순위 점수 카드
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Priority Score")
                .font(ZOOMINFont.title3)
                .foregroundStyle(Color.textPrimary)

            ZOOMINPriorityBar(score: Double(issue.priorityScore))

            // 4개 세부 항목
            HStack(spacing: 0) {
                priorityFactorCell(label: "Safety",  value: issue.safetyRisk,   max: 5, color: Color.riskCritical)
                priorityFactorCell(label: "Urgency", value: issue.urgency,       max: 5, color: Color.riskHigh)
                priorityFactorCell(label: "Impact",  value: issue.publicImpact,  max: 5, color: Color.statusReviewing)
                priorityFactorCell(label: "Support", value: issue.supportScore,  max: 3, color: Color.zoominBlue)
            }

            Text("Support Score는 조작 방지를 위해 최대 3점으로 제한됩니다.")
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.textTertiary)
        }
        .zoominCard()
    }

    private func priorityFactorCell(label: String, value: Int, max: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(ZOOMINFont.title2)
                .foregroundStyle(color)
            Text("/ \(max)")
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.textTertiary)
            Text(label)
                .font(ZOOMINFont.micro)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // Support 버튼 섹션
    private var supportSection: some View {
        HStack(spacing: 16) {
            // Support 버튼
            Button {
                issueStore.supportIssue(issueID: issue.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                        .foregroundStyle(Color.zoominBlue)
                    Text("Support \(issue.supportCount)")
                        .font(ZOOMINFont.bodyBold)
                        .foregroundStyle(Color.zoominBlue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.zoominBlueLight)
                .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge))
                .overlay(
                    RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge)
                        .stroke(Color.zoominBlue.opacity(0.3), lineWidth: 1)
                )
            }

            // 포인트 뱃지
            ZOOMINPointsBadge(points: issue.rewardPoints)
        }
    }

    // 탭 섹션 (Details / Updates / Comments)
    private var tabSection: some View {
        VStack(spacing: 0) {
            // 탭 헤더
            HStack(spacing: 0) {
                ForEach(Array(detailTabs.enumerated()), id: \.offset) { idx, tab in
                    Button {
                        withAnimation { selectedTab = idx }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab)
                                .font(ZOOMINFont.captionBold)
                                .foregroundStyle(selectedTab == idx ? Color.zoominBlue : Color.textTertiary)
                            Rectangle()
                                .fill(selectedTab == idx ? Color.zoominBlue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge))

            // 탭 콘텐츠
            Group {
                switch selectedTab {
                case 0: detailsTabContent
                case 1: updatesTabContent
                default: commentsPlaceholder
                }
            }
            .padding(.top, 8)
        }
        .zoominCard()
    }

    private var detailsTabContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            detailRow(icon: "tag.fill",          label: "카테고리",   value: issue.category.displayName)
            detailRow(icon: "calendar",          label: "신고일",     value: issue.reportDate.formatted(date: .long, time: .omitted))
            if let completion = issue.completionDate {
                detailRow(icon: "checkmark.seal.fill", label: "완료일", value: completion.formatted(date: .long, time: .omitted))
            }
            if let summary = issue.completionSummary {
                detailRow(icon: "doc.text.fill",  label: "완료 요약",  value: summary)
            }
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.zoominBlue)
                .frame(width: 20)
            Text(label)
                .font(ZOOMINFont.captionBold)
                .foregroundStyle(Color.textSecondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(ZOOMINFont.caption)
                .foregroundStyle(Color.textPrimary)
        }
    }

    private var updatesTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(IssueStatus.allCases, id: \.self) { st in
                HStack(spacing: 12) {
                    // 타임라인 점
                    ZStack {
                        Circle()
                            .stroke(st.badgeColor.opacity(0.3), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        if issue.status == st || statusOrder(st) < statusOrder(issue.status) {
                            Circle()
                                .fill(st.badgeColor)
                                .frame(width: 20, height: 20)
                            Image(systemName: st.symbolName)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(st.displayName)
                            .font(ZOOMINFont.captionBold)
                            .foregroundStyle(statusOrder(st) <= statusOrder(issue.status) ? st.badgeColor : Color.textTertiary)
                        if issue.status == st {
                            Text("현재 상태")
                                .font(ZOOMINFont.micro)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func statusOrder(_ s: IssueStatus) -> Int {
        switch s {
        case .received: return 0
        case .reviewing: return 1
        case .inProgress: return 2
        case .completed: return 3
        }
    }

    private var commentsPlaceholder: some View {
        ZOOMINEmptyStateView(
            mood: .thinking,
            title: "댓글 없음",
            message: "아직 댓글이 없습니다."
        )
    }
}

// MARK: - Preview

#Preview("MapView") {
    MapView()
        .environmentObject(IssueStore())
}

#Preview("IssueDetail") {
    NavigationStack {
        IssueDetailView(issue: IssueStore().issues[0])
            .environmentObject(IssueStore())
    }
}

// MARK: - 검색 시트

struct IssueSearchSheet: View {
    @EnvironmentObject var issueStore: IssueStore
    @Binding var searchText: String
    var onSelect: (Issue) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private var searchResults: [Issue] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if query.isEmpty { return issueStore.sortedByPriority }
        return issueStore.issues.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.category.displayName.localizedCaseInsensitiveContains(query) ||
            $0.description.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfaceSecondary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 검색 바
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.textSecondary)
                        TextField("신고 제목, 카테고리 검색...", text: $searchText)
                            .font(ZOOMINFont.body)
                            .focused($isFocused)
                            .submitLabel(.search)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.vertical, 12)

                    // 결과 수
                    HStack {
                        Text(searchText.isEmpty ? "전체 신고" : "검색 결과")
                            .font(ZOOMINFont.captionBold)
                            .foregroundStyle(Color.textSecondary)
                        Text("\(searchResults.count)건")
                            .font(ZOOMINFont.captionBold)
                            .foregroundStyle(Color.zoominBlue)
                        Spacer()
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 6)

                    // 결과 목록
                    if searchResults.isEmpty {
                        Spacer()
                        ZOOMINEmptyStateView(
                            mood: .search,
                            title: "검색 결과 없음",
                            message: "'\(searchText)'에 해당하는 신고를 찾을 수 없습니다."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(searchResults) { issue in
                                    SearchResultRow(issue: issue)
                                        .onTapGesture {
                                            onSelect(issue)
                                        }
                                }
                            }
                            .padding(.horizontal, ZOOMINLayout.paddingMedium)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("신고 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.zoominBlue)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 검색 결과 행

private struct SearchResultRow: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            // 카테고리 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: issue.category.symbolName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(issue.category.markerColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(ZOOMINFont.bodyBold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(issue.category.displayName)
                    .font(ZOOMINFont.caption)
                    .foregroundStyle(Color.textSecondary)
                HStack(spacing: 6) {
                    ZOOMINStatusBadge(status: issue.status)
                    ZOOMINRiskBadge(level: issue.safetyRisk)
                }
            }

            Spacer()

            // 우선순위 점수
            VStack(spacing: 2) {
                Text(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))
                    .font(ZOOMINFont.title3)
                    .foregroundStyle(scoreColor)
                Text("Score")
                    .font(ZOOMINFont.micro)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .zoominCard(padding: 12)
        // High 우선순위 강조 바
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.riskCritical)
                    .frame(width: 3)
                    .padding(.vertical, 10)
            }
        }
    }

    private var scoreColor: Color {
        switch issue.priorityLevel {
        case .high:   return .riskCritical
        case .medium: return .riskHigh
        case .low:    return .riskLow
        }
    }
}

