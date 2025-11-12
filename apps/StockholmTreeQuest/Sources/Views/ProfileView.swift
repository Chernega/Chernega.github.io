import SwiftUI

struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var selectedLanguage: AppLanguage
    @EnvironmentObject private var treeStore: TreeStore
    @EnvironmentObject private var localization: LocalizationProvider

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
        .navigationTitle(localization.string("profile.title"))
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
                    Text(localization.string("profile.greeting"))
                        .font(.title.bold())
                    Text(localization.string(viewModel.statusKey))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))
                    Label("\(treeStore.totalTreesDiscovered) \(localization.string("profile.total_trees"))", systemImage: "leaf.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
            }
            Text(localization.string("profile.mission"))
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.string("profile.level"))
                .font(.headline)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lvl \(viewModel.level)")
                        .font(.title.bold())
                    ProgressView(value: viewModel.progressToNextLevel)
                        .progressViewStyle(.linear)
                        .tint(AppTheme.accent)
                        .scaleEffect(x: 1, y: 1.3, anchor: .center)
                    Text(localization.string("profile.next_level"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(spacing: 8) {
                    Text("✨")
                        .font(.system(size: 48))
                    Text(localization.string("profile.energy"))
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
            Text(localization.string("profile.achievements"))
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)], spacing: 16) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementCard(achievement: achievement, isUnlocked: achievement.isUnlocked(totalTrees: treeStore.totalTreesDiscovered), localization: localization)
                }
            }
        }
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.string("profile.language"))
                .font(.headline)
            Picker(localization.string("profile.language"), selection: $selectedLanguage) {
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
    let localization: LocalizationProvider

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
                Text(localization.string(achievement.titleKey))
                    .font(.headline)
                Text(localization.string(achievement.subtitleKey))
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
    let localization = LocalizationProvider()
    localization.update(language: .english)
    return ProfileView(viewModel: ProfileViewModel(treeStore: store), selectedLanguage: .constant(.english))
        .environmentObject(store)
        .environmentObject(localization)
}
