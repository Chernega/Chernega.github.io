import SwiftUI
import Charts
import MapKit

struct FriendsView: View {
    @EnvironmentObject private var friendsService: FriendsService
    @EnvironmentObject private var localization: LocalizationProvider
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if friendsService.isAuthenticated && !friendsService.isLoading {
                    Button(action: refresh) {
                        Label(localization.string("friends.refresh"), systemImage: "arrow.clockwise")
                            .labelStyle(.titleAndIcon)
                    }
                    .tint(AppTheme.accent)
                }
            }
        }
        .navigationTitle(localization.string("friends.title"))
        .task { await refreshIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if !friendsService.isAuthenticated {
            authenticationPrompt
        } else if friendsService.isLoading && friendsService.friends.isEmpty {
            ProgressView(localization.string("friends.loading"))
                .progressViewStyle(.circular)
                .tint(.white)
        } else if friendsService.friends.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(localization.string("friends.headline"))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    chartSection
                    friendList
                }
            }
        }
    }

    private var authenticationPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.accent)
            Text(localization.string("friends.gamecenter.required"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(localization.string("friends.gamecenter.description"))
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: authenticateGameCenter) {
                Text(localization.string("friends.gamecenter.sign_in"))
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent.gradient.opacity(0.95))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
                    .foregroundStyle(.white)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.accent)
            Text(localization.string("friends.empty.title"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(localization.string("friends.empty.subtitle"))
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button(action: GameCenterHelper.shared.presentFriendsList) {
                Text(localization.string("friends.empty.add_button"))
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent.gradient.opacity(0.95))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
            }
            if let error = friendsService.lastError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.string("friends.chart.title"))
                    .font(.title3.bold())
                Spacer()
                Text(localization.string("friends.chart.subtitle"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

            if friendsService.friends.isEmpty {
                Text(localization.string("friends.chart.empty"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            } else {
                Chart(friendsService.friends) { friend in
                    BarMark(
                        x: .value("Trees", friend.totalTrees),
                        y: .value("Friend", friend.displayName)
                    )
                    .foregroundStyle(AppTheme.accent.gradient)
                    .annotation(position: .trailing) {
                        Text("\(friend.totalTrees)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(max(220, friendsService.friends.count * 48)))
                .padding(18)
                .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.frost, lineWidth: 1)
                )
            }
        }
    }

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(friendsService.friends) { friend in
                NavigationLink(value: friend.id) {
                    FriendRow(friend: friend, localization: localization)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Friend.ID.self) { friendID in
            if let friend = friendsService.friend(for: friendID) {
                FriendDetailView(friend: friend, localization: localization)
            } else {
                ProgressView()
            }
        }
    }

    private func authenticateGameCenter() {
        GameCenterHelper.shared.authenticate { result in
            Task { @MainActor in
                switch result {
                case .success:
                    await friendsService.refresh()
                case .failure(let error):
                    friendsService.lastError = error.localizedDescription
                }
            }
        }
    }

    private func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            await friendsService.refresh()
            await MainActor.run { isRefreshing = false }
        }
    }

    private func refreshIfNeeded() async {
        guard friendsService.isAuthenticated else { return }
        await friendsService.refresh()
    }
}

private struct FriendRow: View {
    let friend: Friend
    let localization: LocalizationProvider

    var body: some View {
        HStack(spacing: 16) {
            Text(friend.avatar)
                .font(.largeTitle)
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                Text("\(friend.totalTrees) \(localization.string("friends.row.trees"))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                if !friend.city.isEmpty {
                    Text(friend.city)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(18)
        .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.frost, lineWidth: 1)
        )
    }
}

private struct FriendDetailView: View {
    let friend: Friend
    let localization: LocalizationProvider

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                visitMap
                visitTimeline
            }
            .padding(20)
            .background(AppTheme.gradient.ignoresSafeArea())
        }
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text(friend.avatar)
                .font(.system(size: 56))
                .frame(width: 72, height: 72)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            VStack(alignment: .leading, spacing: 8) {
                Text(friend.displayName)
                    .font(.title2.bold())
                Text("\(friend.totalTrees) \(localization.string("friends.detail.trees"))")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                if !friend.city.isEmpty {
                    Label(friend.city, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var visitMap: some View {
        if friend.visits.isEmpty {
            VStack(spacing: 12) {
                Text(localization.string("friends.detail.no_visits"))
                    .font(.headline)
                Text(localization.string("friends.detail.no_visits.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(AppTheme.frost, lineWidth: 1)
            )
        } else {
            Map {
                ForEach(friend.visits) { visit in
                    Annotation(visit.createdAt.formatted(.dateTime.month().day()), coordinate: visit.coordinate) {
                        Text("🎄")
                            .font(.title)
                            .padding(6)
                            .background(AppTheme.glassBackground, in: Circle())
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(AppTheme.frost, lineWidth: 1)
            )
        }
    }

    private var visitTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.string("friends.detail.timeline"))
                .font(.headline)
            if friend.visits.isEmpty {
                Text(localization.string("friends.detail.no_visits.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(friend.visits.sorted(by: { $0.createdAt > $1.createdAt })) { visit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(visit.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.bold())
                            Text("\(String(format: "%.4f", visit.latitude)), \(String(format: "%.4f", visit.longitude))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.frost, lineWidth: 1)
                    )
                }
            }
        }
    }
}

#Preview {
    let localization = LocalizationProvider()
    localization.update(language: .english)
    let service = FriendsService(authenticationProvider: { true }, loader: { [] })
    return FriendsView()
        .environmentObject(service)
        .environmentObject(localization)
}
