import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedLanguage: AppLanguage
    @EnvironmentObject private var treeStore: TreeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                progressCard
                achievementsSection
                languagePicker
            }
            .padding(20)
            .background {
                AppTheme.gradient.ignoresSafeArea()
            }
            .onChange(of: treeStore.markers) { _ in
                viewModel.recalculate()
            }
        }
        .navigationTitle(NSLocalizedString("profile.title", comment: ""))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 72, height: 72)
                    Text("🧝‍♂️")
                        .font(.system(size: 48))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("profile.greeting", comment: ""))
                        .font(.title.bold())
                    Text(viewModel.statusTitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Label("\(treeStore.totalTreesDiscovered) \(NSLocalizedString("profile.total_trees", comment: ""))", systemImage: "leaf.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
            }
            Text(NSLocalizedString("profile.mission", comment: ""))
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("profile.level", comment: ""))
                .font(.headline)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lvl \(viewModel.level)")
                        .font(.title.bold())
                    ProgressView(value: viewModel.progressToNextLevel)
                        .progressViewStyle(.linear)
                        .tint(AppTheme.accent)
                        .scaleEffect(x: 1, y: 1.3, anchor: .center)
                    Text(NSLocalizedString("profile.next_level", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 48))
                    Text(NSLocalizedString("profile.energy", comment: ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(22)
        .background(AppTheme.glassBackground, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.frost, lineWidth: 1)
        )
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("profile.achievements", comment: ""))
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)], spacing: 16) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementCard(achievement: achievement, isUnlocked: achievement.isUnlocked(totalTrees: treeStore.totalTreesDiscovered))
                }
            }
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("profile.language", comment: ""))
                .font(.headline)
            Picker(NSLocalizedString("profile.language", comment: ""), selection: $selectedLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(achievement.icon)
                    .font(.system(size: 42))
                Spacer()
                Image(systemName: isUnlocked ? "checkmark.seal.fill" : "seal")
                    .foregroundStyle(isUnlocked ? AppTheme.accent : .white.opacity(0.3))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.glassBackground)
        )
        .overlay(
            Group {
                if isUnlocked {
                    LinearGradient(colors: [AppTheme.accent.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.frost, lineWidth: 1)
        )
    }
}

#Preview {
    let store = TreeStore()
    return ProfileView(viewModel: ProfileViewModel(treeStore: store), selectedLanguage: .constant(.english))
        .environmentObject(store)
}
