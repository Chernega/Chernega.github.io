import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import MapKit

struct DiscoveryView: View {
    @StateObject private var viewModel: DiscoveryViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var friendsService: FriendsService
    @EnvironmentObject private var localization: LocalizationProvider
    @State private var safeAreaInsets: EdgeInsets = .init()

    init(treeStore: TreeStore, locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: DiscoveryViewModel(treeStore: treeStore, locationProvider: locationManager))
    }

    @State private var showFullScreenMap = false

    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                mapSection
                timeline
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $viewModel.showAddNoteSheet) {
            AddTreeSheet(noteText: $viewModel.noteText, localization: localization) {
                viewModel.addMarker()
            }
            .presentationDetents([.fraction(0.45), .medium])
            .presentationCornerRadius(32)
            .presentationBackground(.clear)
        }
        .fullScreenCover(isPresented: $showFullScreenMap) {
            FullScreenMapView(
                viewModel: viewModel,
                locationManager: locationManager,
                localization: localization,
                safeAreaInsets: safeAreaInsets
            ) {
                showFullScreenMap = false
            }
        }
        .onAppear { safeAreaInsets = SafeAreaInsetsProvider.currentInsets }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string("discover.title"))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text(localization.string("discover.subtitle"))
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Button(action: viewModel.focusOnUser) {
                    Image(systemName: "location.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.accent)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }

            HStack(spacing: 12) {
                FrostedInfoCard(
                    title: localization.string("discover.total_trees"),
                    value: "\(viewModel.totalTrees)",
                    icon: "sparkles"
                )

                FrostedInfoCard(
                    title: localization.string("discover.friends_active"),
                    value: "\(friendsService.friends.count)",
                    icon: "person.2"
                )
            }
        }
    }

    private var mapSection: some View {
        InteractiveMapView(
            viewModel: viewModel,
            locationManager: locationManager,
            localization: localization,
            safeAreaInsets: safeAreaInsets,
            isFullScreen: false,
            onExpand: { showFullScreenMap = true }
        )
        .frame(height: 360)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.string("discover.timeline"))
                .font(.title3.bold())
                .foregroundStyle(.white)
            if viewModel.markers.isEmpty {
                Text(localization.string("discover.timeline.empty"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.frost, lineWidth: 1)
                    )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.markers) { marker in
                            TimelineCard(marker: marker, localization: localization) {
                                withAnimation(.easeInOut) {
                                    viewModel.removeMarker(marker)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct AddTreeSheet: View {
    @Binding var noteText: String
    let localization: LocalizationProvider
    var onConfirm: () -> Void

    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 48, height: 4)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                Text(localization.string("sheet.add_tree.title"))
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(localization.string("sheet.add_tree.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.75))
                TextField(localization.string("sheet.add_tree.placeholder"), text: $noteText)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                Button {
                    Haptics.impact(.medium)
                    onConfirm()
                } label: {
                    Label(localization.string("sheet.add_tree.button"), systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent.gradient.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CoverageHeatmapOverlay: View {
    let proxy: MapProxy
    let zones: [CoverageZone]

    var body: some View {
        ZStack {
            ForEach(zones) { zone in
                coverageCircle(for: zone)
            }
        }
        .allowsHitTesting(false)
    }

    private func pointsPerMeter(at coordinate: CLLocationCoordinate2D) -> CGFloat? {
        let offsetDelta = 0.0005
        let offset = CLLocationCoordinate2D(latitude: coordinate.latitude + offsetDelta, longitude: coordinate.longitude)
        guard
            let basePoint = proxy.convert(coordinate, to: .local),
            let offsetPoint = proxy.convert(offset, to: .local)
        else { return nil }

        let pointDistance = hypot(basePoint.x - offsetPoint.x, basePoint.y - offsetPoint.y)
        let meters = coordinate.distance(to: offset)
        guard meters > 0 else { return nil }

        return pointDistance / CGFloat(meters)
    }

    @ViewBuilder
    private func coverageCircle(for zone: CoverageZone) -> some View {
        if
            let center = proxy.convert(zone.coordinate, to: .local),
            let pointsPerMeter = pointsPerMeter(at: zone.coordinate),
            pointsPerMeter > 0
        {
            let radiusPoints = max(CGFloat(zone.radius) * pointsPerMeter, 12)

            Circle()
                .fill(AppTheme.coverageFill)
                .frame(width: radiusPoints * 2, height: radiusPoints * 2)
                .overlay(
                    Circle()
                        .stroke(AppTheme.coverageStroke, lineWidth: 2)
                )
                .position(center)
        }
    }
}

private extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let current = CLLocation(latitude: latitude, longitude: longitude)
        let target = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return current.distance(from: target)
    }
}


private struct InteractiveMapView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    let locationManager: LocationManager
    let localization: LocalizationProvider
    let safeAreaInsets: SwiftUI.EdgeInsets
    let isFullScreen: Bool
    let onExpand: (() -> Void)?
    let onDismiss: (() -> Void)?

    init(viewModel: DiscoveryViewModel, locationManager: LocationManager, localization: LocalizationProvider, safeAreaInsets: SwiftUI.EdgeInsets, isFullScreen: Bool, onExpand: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.locationManager = locationManager
        self.localization = localization
        self.safeAreaInsets = safeAreaInsets
        self.isFullScreen = isFullScreen
        self.onExpand = onExpand
        self.onDismiss = onDismiss
    }

    var body: some View {
        MapReader { proxy in
            ZStack(alignment: .topLeading) {
                let tapHandler: (CGPoint) -> Void = { point in
                    if let coordinate = proxy.convert(point, from: .local) {
                        Haptics.impact(.soft)
                        viewModel.prepareMarkerCreation(at: coordinate)
                    }
                }

                Map(
                    position: Binding(
                        get: { viewModel.cameraPosition },
                        set: { viewModel.setCameraPosition($0) }
                    ),
                    interactionModes: .all,
                    content: {
                        if locationManager.lastLocation != nil {
                            UserAnnotation()
                        }
                        ForEach(viewModel.markers) { marker in
                            Annotation("", coordinate: marker.coordinate) {
                                TreeMarkerView(marker: marker, localization: localization)
                            }
                        }
                    }
                )
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.updateVisibleRegion(context.region)
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0).onEnded { value in
                        if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                            tapHandler(value.location)
                        }
                    }
                )

                CoverageHeatmapOverlay(proxy: proxy, zones: viewModel.coverageZones)

                if let pending = viewModel.pendingCoordinate,
                   let point = proxy.convert(pending, to: .local) {
                    SelectedLocationIndicator()
                        .position(point)
                }

                VStack(alignment: .leading, spacing: 10) {
                    if isFullScreen, let onDismiss {
                        Button {
                            Haptics.impact(.soft)
                            onDismiss()
                        } label: {
                            Label("Close", systemImage: "xmark")
                                .labelStyle(.iconOnly)
                                .font(.headline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .foregroundColor(.white)
                    } else if let onExpand {
                        Button {
                            Haptics.impact(.soft)
                            onExpand()
                        } label: {
                            Label("Expand map", systemImage: "arrow.up.left.and.arrow.down.right")
                                .labelStyle(.iconOnly)
                                .font(.headline.weight(.semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .foregroundColor(.white)
                    }
                }
                .padding(.top, safeAreaInsets.top + 12)
                .padding(.leading, 16)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 28, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Button {
                let coordinate = locationManager.lastLocation?.coordinate ?? viewModel.currentMapCenter
                Haptics.impact()
                viewModel.prepareMarkerCreation(at: coordinate)
            } label: {
                Label(localization.string("discover.add_tree"), systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent.gradient.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, (isFullScreen ? safeAreaInsets.bottom : 0) + 24)
        }
        .ignoresSafeArea(isFullScreen ? .all : [])
    }
}

private struct FullScreenMapView: View {
    @ObservedObject var viewModel: DiscoveryViewModel
    let locationManager: LocationManager
    let localization: LocalizationProvider
    let safeAreaInsets: SwiftUI.EdgeInsets
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()
            InteractiveMapView(
                viewModel: viewModel,
                locationManager: locationManager,
                localization: localization,
                safeAreaInsets: safeAreaInsets,
                isFullScreen: true,
                onExpand: nil,
                onDismiss: onDismiss
            )
        }
    }
}

private struct SelectedLocationIndicator: View {
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(.white, AppTheme.accent)
                .shadow(radius: 6)
            Text("New tree")
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
}

private struct FrostedInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.white)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.frost, lineWidth: 1)
        )
    }
}

private enum SafeAreaInsetsProvider {
    static var currentInsets: EdgeInsets {
        #if canImport(UIKit)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            let inset = window.safeAreaInsets
            return EdgeInsets(top: inset.top, leading: inset.left, bottom: inset.bottom, trailing: inset.right)
        }
        #endif
        return EdgeInsets()
    }
}

private struct TimelineCard: View {
    let marker: TreeMarker
    let localization: LocalizationProvider
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(marker.note.isEmpty ? localization.string("discover.marker") : marker.note)
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    Haptics.impact(.soft)
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Text(marker.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Label(
                "\(String(format: "%.4f", marker.latitude)), \(String(format: "%.4f", marker.longitude))",
                systemImage: "location"
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(18)
        .frame(width: 220)
        .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.frost, lineWidth: 1)
        )
    }
}

private struct TreeMarkerView: View {
    let marker: TreeMarker
    let localization: LocalizationProvider

    var body: some View {
        VStack(spacing: 4) {
            Text("🎄")
                .font(.largeTitle)
                .shadow(radius: 4)
            Text(marker.note.isEmpty ? localization.string("discover.marker") : marker.note)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.glassBackground, in: Capsule())
                .foregroundStyle(.white)
        }
    }
}

private struct UserAnnotationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 22, height: 22)
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 12, height: 12)
        }
        .shadow(color: AppTheme.accent.opacity(0.6), radius: 8)
    }
}

#if canImport(UIKit)
@MainActor
private enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
#else
@MainActor
private enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {}
}
#endif

#Preview {
    let treeStore = TreeStore()
    let locationManager = LocationManager()
    let friendsService = FriendsService()
    let localization = LocalizationProvider()
    localization.update(language: .english)
    return DiscoveryView(treeStore: treeStore, locationManager: locationManager)
        .environmentObject(locationManager)
        .environmentObject(friendsService)
        .environmentObject(localization)
}
