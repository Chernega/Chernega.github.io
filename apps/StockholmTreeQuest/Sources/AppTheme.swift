import SwiftUI

enum AppTheme {
    static let gradient = LinearGradient(
        colors: [Color(red: 0.11, green: 0.15, blue: 0.3), Color(red: 0.31, green: 0.1, blue: 0.35), Color(red: 0.6, green: 0.16, blue: 0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let glassBackground = Color.white.opacity(0.08)
    static let accent = Color(red: 0.94, green: 0.27, blue: 0.35)
    static let frost = Color.white.opacity(0.35)
    static let coverageFill = Color.yellow.opacity(0.14)
    static let coverageStroke = Color.yellow.opacity(0.35)

    static func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.accent)

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.accent)
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor.white
        ], for: .selected)

        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppTheme.accent)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.2)
    }
}
