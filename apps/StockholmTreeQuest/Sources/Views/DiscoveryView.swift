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
        .task { @MainActor in safeAreaInsets = SafeAreaInsetsProvider.currentInsets() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.string("discover.title"))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text(localization.string("discover.subtitle"))
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
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
                        if let pending = viewModel.pendingCoordinate {
                            Annotation("Pending", coordinate: pending) {
                                Text("🎄")
                                    .font(.title)
                                    .shadow(radius: 4)
                            }
                        }
                    }
                )
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.updateVisibleRegion(context.region)
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                }
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            tapHandler(value.location)
                        }
                    )

                HStack {
                    if isFullScreen, let onDismiss {
                        Button {
                            Haptics.impact(.soft)
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    } else if let onExpand {
                        Button {
                            Haptics.impact(.soft)
                            onExpand()
                        } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.headline.weight(.semibold))
                                .padding(10)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }

                    Spacer()

                    Button {
                        Haptics.impact(.medium)
                        locationManager.refreshLocation()
                        viewModel.focusOnUser()
                    } label: {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .foregroundColor(.white)
                .padding(.top, safeAreaInsets.top + 12)
                .padding(.horizontal, 16)
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

@MainActor
private enum SafeAreaInsetsProvider {
    static func currentInsets() -> EdgeInsets {
        #if canImport(UIKit)
        let inset = UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
        return EdgeInsets(top: inset.top, leading: inset.left, bottom: inset.bottom, trailing: inset.right)
        #else
        return EdgeInsets()
        #endif
    }
}
#if canImport(UIKit)
@MainActor
private extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
#endif

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
