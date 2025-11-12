# Stockholm Tree Quest iOS

A SwiftUI-powered iOS application for capturing Christmas trees anywhere on the planet, featuring a premium, modern aesthetic inspired by leading fintech apps.

## Highlights
- Live location tracking with MapKit and beautiful festive theming.
- Glassmorphism UI tuned for iPhone with lightning-fast launch and persistence via JSON storage.
- Friend leaderboard with Charts and detailed friend maps.
- Dynamic profile with achievements, gamified levels, and manual language selection (English, Spanish, French, German, Simplified Chinese).

## Requirements
- Xcode 15 or newer
- iOS 17.4+ deployment target (validated on iPhone 15 Pro today and sized for upcoming iPhone 17 Pro / Pro Max hardware)

## Getting Started
1. Open `StockholmTreeQuest.xcodeproj` directly in Xcode 15 or newer.
2. Select your signing team under **Signing & Capabilities**.
3. Choose the **iPhone 15 Pro (iOS 17.4)** simulator—or a newer flagship such as the iPhone 17 Pro / Pro Max as soon as Apple ships those runtimes—and press **Run**.

### Troubleshooting launch issues
- If the simulator opens to a blank homescreen, make sure the **StockholmTreeQuest** scheme is selected next to the Run button and press **⌘R** again.
- When switching between the tracked `.xcodeproj` and a locally regenerated one, clean Derived Data (**Shift+⌘+K**) to avoid stale build metadata.
- Confirm the simulator runtime matches or exceeds iOS 17.4; older runtimes do not include all of the MapKit APIs used by the discovery map.

> Prefer regenerating from source? You can still install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate` from the app directory; the tracked project file matches the `project.yml` template.

The code follows Apple's Human Interface Guidelines with touch-friendly spacing, SF Symbols, haptic-ready interactions, and energy-efficient background behavior.

## Automated Tests
Unit tests cover tree persistence, discovery logic, friend data loading, and gamified profile calculations. Run them from the project root:

```bash
xcodebuild test \
  -project StockholmTreeQuest.xcodeproj \
  -scheme StockholmTreeQuest \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.4'
```

> Tip: when Apple ships iPhone 17 Pro / Pro Max simulators, swap the destination to their identifiers to keep parity with flagship hardware.

## QA Validation
A detailed manual QA matrix—covering localization, accessibility, offline usage, and performance—is available in [`QA/ManualTestPlan.md`](QA/ManualTestPlan.md). Pair it with the flagship hardware checklist in [`QA/DeviceCompatibilityChecklist.md`](QA/DeviceCompatibilityChecklist.md) to confirm iPhone 17 Pro / Pro Max readiness.
