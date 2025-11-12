# Device Compatibility Checklist

This checklist supplements the manual test plan with device-specific validations so the Stockholm Tree Quest experience feels consistently premium on Apple's flagship hardware.

## Primary Targets
- **iPhone 17 Pro (iOS 18 seed and GA)**
- **iPhone 17 Pro Max (iOS 18 seed and GA)**
- **iPhone 15 Pro (iOS 17.4)** as the current production baseline

## Validation Steps
1. **Install & Launch**
   - Verify cold start < 2 seconds and no launch screen clipping on Dynamic Island devices.
   - Confirm status bar text remains legible against the glassmorphism gradient.
2. **Discovery Tab**
   - Check that the map respects the new 396 x 852 pt safe area on iPhone 17 Pro Max.
   - Ensure the add button and focus control sit inside safe-area insets in both portrait orientations.
3. **Friends Tab**
   - Validate Charts renders at 120 Hz ProMotion without stutter on iPhone 17 models.
   - Confirm friend detail maps load custom annotations without duplicated drops.
4. **Profile Tab**
   - Review Dynamic Type Large/Extra Large to guarantee achievement grid remains two columns on iPhone 17 Pro.
   - Test haptic feedback from segmented picker (hardware only).
5. **Localization & Persistence**
   - Switch languages across all devices and relaunch to ensure the selection persists per device locale.
6. **App Store Compliance**
   - Capture 6.7" and 6.1" screenshots per App Store Connect's latest marketing asset matrix.
   - Run `xcodebuild -showdestinations` to confirm the iPhone 17 Pro simulators are available before releasing builds targeting iOS 18.

## Sign-off Criteria
- All steps above executed with no blockers.
- Zero layout regressions captured in screenshots and shared via QA artifacts.
- Any simulator-only issues reconciled on physical hardware before App Store submission.
