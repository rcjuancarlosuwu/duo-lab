# Environment

Captured 2026-09-21 on macOS 26.6.2 (25G83), Apple silicon.

## Starting state (before any change)

The machine did **not** meet the lab requirements as received:

| Requirement | Asked for | Found |
|---|---|---|
| Xcode | 27.1 | 27.0 (27A266a) |
| iOS simulator runtime | 27.x with iPhone Duo | iOS 27.0 (24A434), iOS 26.5 (23F77) |
| Flutter | >= 3.47.5 | 3.38.7 (rev `3b62efc2a3`, 2026-01-13) |
| iPhone Duo device type | present | absent |

`xcrun simctl list devicetypes | grep -i -E "duo|fold"` returned nothing under Xcode 27.0.
Newest iPhone device types available were iPhone 18 Pro / 18 Pro Max / Air / 17 family.

No iPad or other device was substituted as a proxy.

## Changes made to reach a usable lab

1. Installed **Xcode 27.1 beta (27A9269)** from `Xcode_27.1_beta.xip`
   (2,027,292,809 bytes), signature verified against Apple Root CA via
   `pkgutil --check-signature`. Installed side by side as
   `/Applications/Xcode-27.1-beta.app`; Xcode 27.0 left untouched at
   `/Applications/Xcode.app`.
   All Xcode-facing commands in this lab run with
   `DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer`,
   so the machine-wide `xcode-select` still points at 27.0.
2. Installed **Flutter 3.47.5-stable** via mise and pinned it in
   `duo-lab/mise.toml`. The global mise default stays at 3.38.7-stable.

## `flutter --version`

```
Flutter 3.47.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6a19cca564 (4 days ago) • 2026-09-17 14:13:22 -0400
Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (4 days ago) • 2026-09-16 18:35:09.000Z
Tools • Dart 3.13.4
```

## `flutter doctor -v`

```
[✓] Flutter (Channel stable, 3.47.5, on macOS 26.6.2 25G83 darwin-arm64, locale en-PE) [1,460ms]
    • Flutter version 3.47.5 on channel stable at /Users/rcjuancarlosuwu/.local/share/mise/installs/flutter/3.47.5-stable
    • Upstream repository https://github.com/flutter/flutter.git
    • Framework revision 6a19cca564 (4 days ago), 2026-09-17 14:13:22 -0400
    • Engine revision af7e796e16
    • Dart version 3.13.4
    • DevTools version 2.60.0
    • Feature flags: enable-web, enable-linux-desktop, enable-macos-desktop, enable-windows-desktop, enable-android, enable-ios, cli-animations, enable-native-assets, enable-record-use, no-enable-swift-package-manager, omit-legacy-version-file, enable-lldb-debugging, enable-uiscene-migration

[✓] Android toolchain - develop for Android devices (Android SDK version 36.0.0) [1,561ms]
    • Android SDK at /Users/rcjuancarlosuwu/Library/Android/sdk
    • Emulator version 37.1.11.0 (build_id 15917651) (CL:N/A)
    • Platform android-36, build-tools 36.0.0
    • Java version OpenJDK Runtime Environment (build 21.0.8+-14196175-b1038.72)
    • All Android licenses accepted.

[✓] Xcode - develop for iOS and macOS (Xcode 27.1) [2.6s]
    • Xcode at /Applications/Xcode-27.1-beta.app/Contents/Developer
    • Build 27A9269
    • CocoaPods version 1.17.0

[✓] Chrome - develop for the web [5ms]
    • Chrome at /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

[✓] Connected device (3 available) [7.4s]
    • Juan Carlos’s iPhone (wireless) (mobile) • 00008130-000E142802A0001C • ios            • iOS 26.5.2 23F84
    • macOS (desktop)                          • macos                     • darwin-arm64   • macOS 26.6.2 25G83 darwin-arm64
    • Chrome (web)                             • chrome                    • web-javascript • Google Chrome 153.0.8010.52

[✓] Network resources [946ms]
    • All expected network resources are available.

• No issues found!
```

## `xcodebuild -version`

With `DEVELOPER_DIR` pointed at the beta:

```
Xcode 27.1
Build version 27A9269
```

The stock `/Applications/Xcode.app` still reports:

```
Xcode 27.0
Build version 27A266a
```

## `xcrun simctl list devices available` — Duo lines

Under Xcode 27.0 the grep for `duo|fold` matched nothing.

Under Xcode 27.1 beta the **device type** appears:

```
iPhone Duo (com.apple.CoreSimulator.SimDeviceType.iPhone-Duo)
```

but no Duo *device* can be instantiated yet, because the runtime it needs is
not installed:

```
$ xcrun simctl create "duo-on-270" com.apple.CoreSimulator.SimDeviceType.iPhone-Duo \
    com.apple.CoreSimulator.SimRuntime.iOS-27-0
An error was encountered processing the command (domain=com.apple.CoreSimulator.SimError, code=403):
Incompatible device
Unable to create a device for device type: iPhone Duo (com.apple.CoreSimulator.SimDeviceType.iPhone-Duo), runtime: iOS 27.0 (27.0 - 24A434) - com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

This is a measured confirmation that the iPhone Duo requires the **iOS 27.1**
runtime specifically. iOS 27.0 is rejected outright.

## Runtimes installed

```
iOS 27.0 (27.0 - 24A434) - com.apple.CoreSimulator.SimRuntime.iOS-27-0
iOS 26.5 (26.5 - 23F77) - com.apple.CoreSimulator.SimRuntime.iOS-26-5
```

The iOS 27.1 runtime is not obtainable through the command line channel:

```
$ xcodebuild -downloadPlatform iOS -buildVersion 27.1
Finding content...
iOS 27.1 is not available for download.
```

It is being fetched through Xcode 27.1 beta's Settings → Components instead.

## Status

**Blocked pending the iOS 27.1 simulator runtime download.** Everything else is in place.
