import SwiftUI
import Charts
import MapKit

struct FriendsView: View {
    @EnvironmentObject private var friendsService: FriendsService

    var body: some View {
        ZStack {
            AppTheme.gradient
                .ignoresSafeArea()
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .navigationTitle(NSLocalizedString("friends.title", comment: ""))
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(NSLocalizedString("friends.headline", comment: ""))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                chartSection
                friendList
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("friends.chart.title", comment: ""))
                    .font(.title3.bold())
                Spacer()
                Text(NSLocalizedString("friends.chart.subtitle", comment: ""))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }

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

    private var friendList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(friendsService.friends) { friend in
                NavigationLink(value: friend.id) {
                    FriendRow(friend: friend)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(for: Friend.ID.self) { friendID in
            if let friend = friendsService.friend(for: friendID) {
                FriendDetailView(friend: friend)
            } else {
                ProgressView()
            }
        }
    }
}

private struct FriendRow: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 16) {
            Text(friend.avatar)
                .font(.largeTitle)
                .frame(width: 56, height: 56)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                Text("\(friend.totalTrees) \(NSLocalizedString("friends.row.trees", comment: ""))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                Text(friend.city)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
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
                Text("\(friend.totalTrees) \(NSLocalizedString("friends.detail.trees", comment: ""))")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.7))
                Label(friend.city, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
        }
    }

    private var visitMap: some View {
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

    private var visitTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("friends.detail.timeline", comment: ""))
                .font(.headline)
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

#Preview {
    FriendsView()
        .environmentObject(FriendsService())
}
