import SwiftUI
import MapKit

struct DiscoveryView: View {
    @StateObject private var viewModel: DiscoveryViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var friendsService: FriendsService
    @EnvironmentObject private var localization: LocalizationProvider

    init(treeStore: TreeStore, locationManager: LocationManager) {
        _viewModel = StateObject(wrappedValue: DiscoveryViewModel(treeStore: treeStore, locationProvider: locationManager))
    }

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
            .presentationDetents([.fraction(0.4)])
            .presentationBackground(.ultraThinMaterial)
        }
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
        Map(
            coordinateRegion: viewModel.currentRegion,
            interactionModes: .all,
            showsUserLocation: locationManager.lastLocation != nil,
            annotationItems: viewModel.markers
        ) { marker in
            MapAnnotation(coordinate: marker.coordinate) {
                TreeMarkerView(marker: marker, localization: localization)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .bottomTrailing) {
            Button {
                let coordinate = locationManager.lastLocation?.coordinate ?? viewModel.currentRegion.wrappedValue.center
                viewModel.prepareMarkerCreation(at: coordinate)
            } label: {
                Label(localization.string("discover.add_tree"), systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent.gradient.opacity(0.9))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
                    .foregroundStyle(.white)
            }
            .padding(20)
            .buttonStyle(.plain)
        }
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
                                viewModel.removeMarker(marker)
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
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 48, height: 4)
                .frame(maxWidth: .infinity)
            Text(localization.string("sheet.add_tree.title"))
                .font(.title3.bold())
            Text(localization.string("sheet.add_tree.subtitle"))
                .font(.callout)
                .foregroundStyle(.secondary)
            TextField(localization.string("sheet.add_tree.placeholder"), text: $noteText)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            Button(action: onConfirm) {
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
        .background(AppTheme.gradient.opacity(0.85))
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
                Button(role: .destructive, action: onDelete) {
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
