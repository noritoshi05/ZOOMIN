// MapView.swift
// ZOOMIN — Member 1
// Role: Map screen / Report markers / Bottom Nearby Issues card / IssueDetailView navigation
// Design: Full ZOOMINStyle applied / Urban infrastructure management platform

import SwiftUI
import MapKit

// MARK: - MapView

struct MapView: View {

    @EnvironmentObject var issueStore: IssueStore

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
                mapBody.ignoresSafeArea(edges: .top)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        locationButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 220)
                    }
                }
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
                                    center: CLLocationCoordinate2D(latitude: issue.latitude, longitude: issue.longitude),
                                    span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                                )
                            )
                        }
                    }
                )
            }
        }
    }

    private var mapBody: some View {
        Map(position: $cameraPosition, interactionModes: .all, selection: $selectedIssueID) {
            ForEach(filteredIssues) { issue in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: issue.latitude, longitude: issue.longitude), anchor: .bottom) {
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
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .including([.publicTransport, .hospital])))
        .mapControls { MapCompass(); MapScaleView() }
    }

    private var nearbyIssuesPanel: some View {
        VStack(spacing: 0) {
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
                statsRow
                Button("View All") { showNearbySheet = true }
                    .font(ZOOMINFont.captionBold)
                    .foregroundStyle(Color.zoominBlue)
                    .padding(.leading, 8)
            }
            .padding(.horizontal, ZOOMINLayout.paddingMedium)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(issueStore.sortedByPriority.prefix(8)) { issue in
                        NearbyIssueCard(
                            issue: issue,
                            isSelected: selectedIssueID == issue.id,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    selectedIssueID = issue.id
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: issue.latitude, longitude: issue.longitude),
                                        span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
                                    ))
                                }
                            },
                            onDetailTap: { selectedIssue = issue }
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
        .sheet(isPresented: $showNearbySheet) { AllIssuesSheet() }
    }

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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").foregroundStyle(Color.zoominBlue)
                Text("ZOOMIN").font(ZOOMINFont.title1).foregroundStyle(Color.zoominBlue)
            }
        }
        ToolbarItem(placement: .navigationBarLeading) {
            Button { showFilter.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: filterCategory == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    if let cat = filterCategory { Text(cat.displayName).font(ZOOMINFont.micro) }
                }
                .foregroundStyle(filterCategory == nil ? Color.textSecondary : Color.zoominBlue)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass").foregroundStyle(Color.zoominBlue)
            }
        }
    }

    private var locationButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                cameraPosition = .userLocation(fallback: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )))
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
                if isSelected {
                    Circle().fill(issue.category.markerColor.opacity(0.20)).frame(width: 52, height: 52)
                }
                Circle()
                    .fill(issue.category.markerColor)
                    .frame(width: isSelected ? 40 : 32, height: isSelected ? 40 : 32)
                    .shadow(color: issue.category.markerColor.opacity(0.5), radius: isSelected ? 8 : 3)
                    .overlay {
                        Image(systemName: issue.category.symbolName)
                            .font(.system(size: isSelected ? 17 : 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                if issue.priorityLevel == .high && !isSelected {
                    Circle().fill(Color.riskCritical).frame(width: 10, height: 10).offset(x: 12, y: -12)
                }
            }
            MarkerTail(color: issue.category.markerColor)
            if isSelected {
                selectedBadge.transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    private var selectedBadge: some View {
        VStack(spacing: 2) {
            Text(issue.title).font(ZOOMINFont.micro).foregroundStyle(Color.textPrimary).lineLimit(1)
            HStack(spacing: 4) {
                ZOOMINRiskBadge(level: issue.safetyRisk)
                Text("Score \(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))")
                    .font(ZOOMINFont.micro).foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
        .offset(y: 6)
    }
}

private struct MarkerTail: View {
    let color: Color
    var body: some View {
        Triangle().fill(color).frame(width: 10, height: 6).offset(y: -1)
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

// MARK: - Nearby Issue Card

struct NearbyIssueCard: View {
    let issue: Issue
    var isSelected: Bool = false
    var onTap: () -> Void = {}
    var onDetailTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12)).frame(width: 56, height: 56)
                if let uiImg = issue.uiImage {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))
                } else {
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 22, weight: .semibold)).foregroundStyle(issue.category.markerColor)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title).font(ZOOMINFont.captionBold).foregroundStyle(Color.textPrimary)
                    .lineLimit(1).frame(width: 120, alignment: .leading)
                Text("2.3 km away").font(ZOOMINFont.micro).foregroundStyle(Color.textSecondary)
                HStack(spacing: 6) { ZOOMINStatusBadge(status: issue.status); ZOOMINRiskBadge(level: issue.safetyRisk) }
            }
            Button { onDetailTap() } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.zoominBlue : Color.textTertiary)
                    .padding(8)
                    .background(isSelected ? Color.zoominBlueLight : Color.clear)
                    .clipShape(Circle())
            }
        }
        .contentShape(Rectangle()).onTapGesture { onTap() }
        .zoominCard(padding: 12).frame(width: 270)
        .overlay(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusLarge).stroke(isSelected ? Color.zoominBlue : Color.clear, lineWidth: 1.5))
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3).fill(Color.riskCritical).frame(width: 3)
                    .padding(.vertical, 10).offset(x: -ZOOMINLayout.paddingMedium + 3)
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
                Button { selectedCategory = nil; dismiss() } label: {
                    filterRow(icon: "map.fill", color: Color.zoominBlue, title: "View All", isSelected: selectedCategory == nil)
                }
                ForEach(IssueCategory.allCases, id: \.self) { cat in
                    Button { selectedCategory = cat; dismiss() } label: {
                        filterRow(icon: cat.symbolName, color: cat.markerColor, title: cat.displayName, isSelected: selectedCategory == cat)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Category Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.zoominBlue)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func filterRow(icon: String, color: Color, title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 26)
            Text(title).font(ZOOMINFont.body).foregroundStyle(Color.textPrimary)
            Spacer()
            if isSelected { Image(systemName: "checkmark").foregroundStyle(Color.zoominBlue).font(.system(size: 14, weight: .semibold)) }
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
                    ZOOMINEmptyStateView(mood: .search, title: "No Reports", message: "No urban facility reports have been submitted yet.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            summaryCard
                                .padding(.horizontal, ZOOMINLayout.paddingMedium)
                                .padding(.top, 12)
                            ForEach(issueStore.sortedByPriority) { issue in
                                AllIssueRow(issue: issue).padding(.horizontal, ZOOMINLayout.paddingMedium)
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
                    Button("Close") { dismiss() }.foregroundStyle(Color.zoominBlue)
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
                    Text("Road · Sidewalk · Construction Safety Report Status")
                        .font(ZOOMINFont.micro)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
                PingoView(mood: .working, size: 44)
            }

            HStack(spacing: 0) {
                statChip(value: issueStore.issues.count, label: "All",         color: Color.zoominBlue)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: highRiskCount,           label: "High Risk",   color: Color.riskCritical)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: inProgressCount,         label: "In Progress", color: Color.statusInProgress)
                Divider().frame(height: 28).padding(.horizontal, 8)
                statChip(value: completedCount,          label: "Done",        color: Color.statusCompleted)
            }
        }
        .zoominCard()
    }

    private func statChip(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(ZOOMINFont.title2).foregroundStyle(color)
            Text(label).font(ZOOMINFont.micro).foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var highRiskCount:   Int { issueStore.issues.filter { $0.priorityLevel == .high }.count }
    private var inProgressCount: Int { issueStore.issues.filter { $0.status == .inProgress }.count }
    private var completedCount:  Int { issueStore.issues.filter { $0.status == .completed }.count }
}

// MARK: - All Issues Row Card

private struct AllIssueRow: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12)).frame(width: 60, height: 60)
                if let uiImg = issue.uiImage {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall))
                } else {
                    Image(systemName: issue.category.symbolName)
                        .font(.system(size: 24, weight: .semibold)).foregroundStyle(issue.category.markerColor)
                }
            }
            // Center info
            VStack(alignment: .leading, spacing: 5) {
                Text(issue.title).font(ZOOMINFont.bodyBold).foregroundStyle(Color.textPrimary).lineLimit(1)
                Text("2.3 km away").font(ZOOMINFont.micro).foregroundStyle(Color.textSecondary)
                HStack(spacing: 6) { ZOOMINStatusBadge(status: issue.status) }
                ZOOMINPriorityBar(score: Double(issue.priorityScore)).frame(width: 160)
            }
            Spacer()
            // Right score
            VStack(spacing: 4) {
                Text(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))
                    .font(ZOOMINFont.title2).foregroundStyle(scoreColor)
                Text("Score").font(ZOOMINFont.micro).foregroundStyle(Color.textSecondary)
            }
        }
        .zoominCard(padding: 12)
        // High priority highlight bar
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3).fill(Color.riskCritical).frame(width: 3).padding(.vertical, 10)
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

// MARK: - Preview

#Preview("MapView") {
    MapView().environmentObject(IssueStore())
}

#Preview("IssueDetail") {
    NavigationStack {
        IssueDetailView(issue: IssueStore().issues[0]).environmentObject(IssueStore())
    }
}

// MARK: - Search Sheet

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
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Color.textSecondary)
                        TextField("Search by title or category...", text: $searchText)
                            .font(ZOOMINFont.body).focused($isFocused).submitLabel(.search)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.surfacePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusMedium))
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.vertical, 12)

                    // Result count
                    HStack {
                        Text(searchText.isEmpty ? "All Reports" : "Search Results")
                            .font(ZOOMINFont.captionBold).foregroundStyle(Color.textSecondary)
                        Text("\(searchResults.count) reports")
                            .font(ZOOMINFont.captionBold).foregroundStyle(Color.zoominBlue)
                        Spacer()
                    }
                    .padding(.horizontal, ZOOMINLayout.paddingMedium)
                    .padding(.bottom, 6)

                    // Result list
                    if searchResults.isEmpty {
                        Spacer()
                        ZOOMINEmptyStateView(
                            mood: .search,
                            title: "No Results",
                            message: "No reports found matching '\(searchText)'."
                        )
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(searchResults) { issue in
                                    SearchResultRow(issue: issue).onTapGesture { onSelect(issue) }
                                }
                            }
                            .padding(.horizontal, ZOOMINLayout.paddingMedium)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Search Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.zoominBlue)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let issue: Issue

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: ZOOMINLayout.cornerRadiusSmall)
                    .fill(issue.category.markerColor.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: issue.category.symbolName)
                    .font(.system(size: 20, weight: .semibold)).foregroundStyle(issue.category.markerColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title).font(ZOOMINFont.bodyBold).foregroundStyle(Color.textPrimary).lineLimit(1)
                Text(issue.category.displayName).font(ZOOMINFont.caption).foregroundStyle(Color.textSecondary)
                HStack(spacing: 6) { ZOOMINStatusBadge(status: issue.status); ZOOMINRiskBadge(level: issue.safetyRisk) }
            }
            Spacer()
            // Priority score
            VStack(spacing: 2) {
                Text(String(format: "%.1f", Double(issue.priorityScore) / 18.0 * 5.0))
                    .font(ZOOMINFont.title3).foregroundStyle(scoreColor)
                Text("Score").font(ZOOMINFont.micro).foregroundStyle(Color.textTertiary)
            }
        }
        .zoominCard(padding: 12)
        // High priority highlight bar
        .overlay(alignment: .leading) {
            if issue.priorityLevel == .high {
                RoundedRectangle(cornerRadius: 3).fill(Color.riskCritical).frame(width: 3).padding(.vertical, 10)
            }
        }
    }

    private var scoreColor: Color {
        switch issue.priorityLevel {
        case .high: return .riskCritical; case .medium: return .riskHigh; case .low: return .riskLow
        }
    }
}

