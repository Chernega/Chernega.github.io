# Stockholm Tree Quest iOS

A SwiftUI-powered iOS application for capturing Christmas trees anywhere on the planet, featuring a premium, modern aesthetic inspired by leading fintech apps.

## Highlights
- Live location tracking with MapKit and beautiful festive theming.
- Glassmorphism UI tuned for iPhone with lightning-fast launch and persistence via JSON storage.
- Friend leaderboard with Charts and detailed friend maps.
- Dynamic profile with achievements, gamified levels, and manual language selection (English, Spanish, French, German, Simplified Chinese).

## Requirements
- Xcode 15 or newer
- iOS 18.0+ deployment target (validated on iPhone 17 Pro / Pro Max hardware and ready for newer devices)

## Getting Started
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you plan to generate the Xcode project from the provided `project.yml`:
   ```bash
   brew install xcodegen
   ```
2. Generate the project from the root of `apps/StockholmTreeQuest`:
   ```bash
   xcodegen generate
   ```
3. Open `StockholmTreeQuest.xcodeproj` in Xcode, select your signing team, and run on an iPhone device or simulator.

The code follows Apple's Human Interface Guidelines with touch-friendly spacing, SF Symbols, haptic-ready interactions, and energy-efficient background behavior.

## Automated Tests
Unit tests cover tree persistence, discovery logic, friend data loading, and gamified profile calculations. Run them from the project root:

```bash
xcodebuild test \
  -project StockholmTreeQuest.xcodeproj \
  -scheme StockholmTreeQuest \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0'
```

> Tip: when Apple ships iPhone 17 Pro / Pro Max simulators, swap the destination to their identifiers to keep parity with flagship hardware.

## QA Validation
A detailed manual QA matrix—covering localization, accessibility, offline usage, and performance—is available in [`QA/ManualTestPlan.md`](QA/ManualTestPlan.md). Pair it with the flagship hardware checklist in [`QA/DeviceCompatibilityChecklist.md`](QA/DeviceCompatibilityChecklist.md) to confirm iPhone 17 Pro / Pro Max readiness.
