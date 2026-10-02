# The iPhone Duo Is Here. What It Actually Means for Your Flutter App

*Author: Juan Ramón*
*Category: Technical / Flutter News*

**Meta Description** (Content Marketing): Apple's first foldable ships October 23. Flutter apps run on it unmodified, so the problems are silent. We measured the iPhone Duo simulator: what Flutter reports, what it does not, and what to fix first.

**Keywords a incluir** (Content Marketing): iPhone Duo Flutter, Flutter foldable support, MediaQuery displayFeatures iOS, adaptive layout Flutter, iOS 27.1 Flutter

**IMAGEN BANNER** (Graphic Designer)

*Título alternativo, por si Content Marketing lo prefiere: "iPhone Duo and Flutter: What We Measured in the Simulator, and What to Fix Before Launch"*

---

## Introduction

Apple announced the iPhone Duo on September 9 and ships it on October 23. It is the company's first foldable, with a 5.4-inch outer display when closed and a 7.6-inch inner display when open.

Existing Flutter apps run on it without changes. No new SDK, no build configuration, no migration. The app opens and looks broadly correct, so most teams will not hear about it from users or from crash reporting.

The Flutter team made the same point on September 26, posting a video of Wonderous running on the device with the caption "We just checked, Flutter still runs everywhere." Wonderous is the gskinner showcase app, and its public repository shows no foldable-specific commits.

The demonstration is accurate. Nothing breaks, which is also why the device is easy to postpone, but several assumptions Flutter layouts rely on no longer hold.

We put a probe app through the iPhone Duo simulator on Xcode 27.1 to find out which ones. Everything below is measured there, on beta software, a month before hardware ships. Numbers from a shipping device may differ.

---

## What to do before October 23

Ordered by cost. The first three need no simulator.

1. **Search for `initState` reads of `MediaQuery`, then for `EdgeInsets.symmetric(horizontal:`, then for `OrientationBuilder`.** Each of the three matches a distinct failure: layout decisions cached at startup go stale when the device unfolds, the Duo's horizontal safe-area insets are not equal, and orientation does not tell you how much width you have when the device has three screen states.

2. **Audit every `setPreferredOrientations` call.** On the inner display it does not take effect, and the error iOS returns does not reliably tell you so. Any screen that assumes a locked orientation has to render correctly without the lock. Details below.

3. **Add 469 × 669 to your layout test matrix.** That is the app's size in Split View on the unfolded screen, and it is worth having regardless of the Duo, as a cheap stand-in for a narrow pane on a large display.

4. **Check `AspectRatio` on video and media surfaces.** A full-width 16:9 box leaves 61.8% of the height unused on the inner display in portrait.

5. **Run the app in the simulator for twenty minutes.** Fold it, unfold it, rotate it, open a dialog, type into a form. Budget setup time; see the tooling section.

6. **Fold the app while a form is half-filled.** Flutter preserves widget state across the transition, so this tests whether your layout handles a size change it was not written to expect.

7. **Hold off on a hinge-aware layout.** Several packages appeared within days of the announcement. Watch the [upstream pull request](https://github.com/flutter/flutter/pull/193025) instead, and read [Apple's Tech Talk on adaptive layouts](https://developer.apple.com/videos/play/tech-talks/111463/) for the design intent.

---

## Orientation, breakpoints and safe areas

### Orientation locking does not work on the inner display

`SystemChrome.setPreferredOrientations` changed the orientation on the outer display and did not change it on the inner one.

Closed, at 466 × 678, requesting landscape produced 678 × 466. Requesting portrait brought it back. Fully open at 951 × 669, requesting portrait left it at 951 × 669.

iOS is not silent about the refusal. On the inner display the simulator logged:

```
Failed to change device orientation: Error Domain=UISceneErrorDomain Code=101
"The current windowing mode does not allow for programmatic changes to interface orientation."
```

That message appeared only on the inner display, and it also fired on a posture change, not just on an explicit call. Note what it blames: the current windowing mode, not the display. That is a different mechanism from the one the behaviour suggests, and we did not isolate it. Treat "the inner display" below as shorthand for the state we measured rather than an established cause.

If your app locks orientation, and video players and camera flows commonly do, the lock does not hold on the inner display.

### Split View drops you below the tablet breakpoint

Most Flutter codebases pick a phone or tablet layout somewhere near 600 logical pixels. On the Duo the same physical screen hands an app 951, 669 or 469 logical pixels depending on orientation and whether another app is beside it.

| State | Logical size | Safe-area padding |
|---|---|---|
| Outer, portrait | 466 × 678 | right 84, bottom 34 |
| Outer, landscape | 678 × 466 | left 84, bottom 34 |
| Inner, landscape | 951 × 669 | right 84, bottom 34 |
| Inner, portrait | 669 × 951 | top 82, bottom 34 |
| Split View, 50% | 469 × 669 | bottom 34 only |

Unfolded you are comfortably on the tablet side at 951, and at 669 rotated. Open Split View and the app gets 469, below the breakpoint, on the unfolded display.

Split View on the Duo is 50/50 only. There is no one-third pane, and dragging the divider past the midpoint dismisses the app.

### The safe-area inset moves between edges

There is a large inset on exactly one edge, and which edge depends on the state: right in inner landscape, left in outer landscape, top in inner portrait, and absent in Split View. It is 84 points horizontally and 82 at the top.

`EdgeInsets.symmetric(horizontal:)` therefore looks correct in inner portrait and in Split View, and is wrong in the three landscape states. The two passing states are the ones you hit first in the simulator.

The inset is not a system control bar. Reading the reserved regions from the native API shows a camera cutout: 84 × 120 points in inner landscape, 134 × 82 in inner portrait, and in the closed state a 37 × 37 lens plus an 84 × 170 block. `MediaQuery.padding` reserves the cutout's width or height across the whole opposite edge, which discards roughly 44,000 square points of otherwise usable screen. `SafeArea` has per-edge flags if you want some of that back.

---

## What MediaQuery does not report

This part is documented rather than discovered.

`MediaQuery.displayFeatures` reports hinges, folds and cutouts, and the framework uses it internally to keep dialogs off a hinge. The [DisplayFeature documentation](https://api.flutter.dev/flutter/dart-ui/DisplayFeature-class.html) states the limitation:

> "This is populated only on Android."

The implementation lives in the Android embedder. The iOS embedder has no equivalent. Across every capture we took, on both displays, in all three postures and in Split View, the list was empty.

In the same frame where `displayFeatures` returned `[]`, the [`foldable` package](https://pub.dev/packages/foldable) reported the device as `partiallyOpen` at 127.8 degrees, with the fold as a 40-point band down the centre of the screen and the camera cutout as a second rectangle. During a fold we logged the angle moving continuously through the intermediate values. The posture, angle and fold geometry are available on the platform side. Flutter does not surface them.

Folding also produces no lifecycle event. `didChangeMetrics` fires and the size changes, so an app can tell that something happened, but nothing identifies the posture, and half-open is indistinguishable from fully open in every value Flutter exposes. Widget state survives: no `State` was recreated, no `initState` ran twice, and the root `build()` did not re-run, because the change is absorbed below `LayoutBuilder` and `MediaQuery`.

Upstream work is in progress. At the time of writing, the [proposal to populate displayFeatures on iOS](https://github.com/flutter/flutter/issues/192515) is open and triaged P2, a [community pull request](https://github.com/flutter/flutter/pull/193025) implementing it is out of draft and awaiting review, and a [second pull request](https://github.com/flutter/flutter/pull/192721) proposes animating between sub-screens on fold. Neither has merged, and stable is 3.47.5. It is unlikely that any of it reaches a stable channel before the device ships. `dual_screen`, the package that once provided `TwoPane`, is Android-only and has not been published since 2023.

---

## Other measurements

**Overlays do not use the width you give them.** On the inner display in landscape, an `AlertDialog` with a 4000-point-wide child painted at 787 points, `showDatePicker` at 496, and `showModalBottomSheet` at 640. The sheet measured 640 in both orientations. That matches Flutter's default maximum sheet width, which would mean it does not widen further regardless of available screen, though we only tested the two widths above.

**16:9 content letterboxes badly.** A 16:9 box across the available width leaves 22.1% of the height unused on the inner display in landscape and 61.8% in portrait. Unfolded the inner screen is 1.42:1, much squarer than a phone in landscape.

**The keyboard closes when the posture changes.** With the keyboard raised, `viewInsets.bottom` measured 264. After switching to half-open it read 0.26. This matches [issue #193096](https://github.com/flutter/flutter/issues/193096).

**Two issues did not reproduce for us.** The [App Switcher preview](https://github.com/flutter/flutter/issues/193078) rendered correctly after crossing all three postures. For [the tab bar issue](https://github.com/flutter/flutter/issues/193035) we measured `TabBar` inside an `AppBar`, a bare `TabBar`, Material 3 `NavigationBar` and `BottomNavigationBar`, and each filled the width its parent gave it, on both displays. One visual detail we did not chase: inside an `AppBar`, the divider under the tabs appears to stop short of the right edge while the bare `TabBar` divider does not. Neither result rules the issue out; a negative in one configuration says little about the one the reporter had.

**Folding looks rough.** We saw no flicker, but the screen goes black for a few seconds during the transition. We did not instrument the duration and are not putting a number on it. [Issue #193088](https://github.com/flutter/flutter/issues/193088) covers this area.

---

## Tooling, if you own a CI pipeline

There is no command-line control for the hinge. The `simctl` subcommand list has no `pose`, `fold` or `hinge`, `simctl ui` covers only appearance and accessibility, and the device plist holds no posture key. Posture is changed by clicking one of three buttons in DeviceHub's bottom toolbar.

Foldable behaviour therefore cannot be a regression test today. Launching the app, capturing per-display screenshots and reading metrics automate normally; the posture change between them has to be done by hand.

Two more things before you budget that twenty minutes. The iPhone Duo device type exists only in Xcode 27.1, still in beta, and requires the iOS 27.1 runtime specifically; creating it against iOS 27.0 fails with `Incompatible device`. That runtime is not available through `xcodebuild -downloadPlatform`, which answers `iOS 27.1 is not available for download`, so it has to be fetched through the Xcode UI. And Xcode 27 no longer ships `Simulator.app`: it is replaced by DeviceHub, which owns the simulator lifecycle and shuts down every booted simulator when you quit it, taking any attached `flutter run` with it.

---

## About these numbers

The measurements come from two sessions on one machine, a week apart: the main matrix on September 21 and a re-measurement of the orientation behaviour on September 28, after the first pass turned out to be poorly evidenced. Both used Xcode 27.1 beta (27A9269), the iOS 27.1 simulator runtime (24A94401), Flutter 3.47.5 stable, and a probe app that renders and logs `MediaQuery`'s size, devicePixelRatio, padding, view insets, view padding, display features, orientation, text scaler and platform brightness.

Values that recurred across dozens of captures, such as the horizontal inset and the empty `displayFeatures`, are solid. The portrait date picker was measured once, and the orientation behaviour rests on a single pair of requests per display. The blackout during a fold is an observation, not a measurement.

One number we could not settle: the published figure for the inner panel is 1878 × 2670 px, and we measured a 2007 × 2853 framebuffer. Same aspect ratio to three decimals, 6.9% larger in each dimension, while the outer display matched its published figure exactly. A render-then-downsample pipeline would explain it, the way the iPhone Plus models rendered at 1242 × 2208 and displayed 1080 × 1920, but a simulator cannot confirm that. The logical sizes above are unaffected, and those are what layout code consumes.

The `foldable` package reported posture, angle and fold geometry consistently with `MediaQuery.padding` in the states we checked, and we would not call it verified: we logged two readings of `closed` with a non-zero angle, and three where it reported no foldable at all. Without hardware there is no ground truth to check it against.

---

## Conclusion

The iPhone Duo is a small device category today, and most of what it asks for is not specific to it. The assumptions it breaks were never reliable: a single screen size known at startup, and symmetric safe-area insets.

Two things are specific to it and belong in planning. Orientation locking did not hold in the state we measured on the inner display. And Flutter has no way, in layout or in lifecycle, to identify the posture, so anything that depends on the fold has to come from a package or from upstream.

The rest is work worth doing anyway. Auditing cached dimensions, deriving layout from constraints and respecting per-edge safe areas improves behaviour on tablets, in Split View, on desktop and on the web, on hardware that already exists. The October 23 date is a reason to schedule that work now.

If you're searching for a **trusted software development partner**, look no further. **Contact us today** to learn how we can help you turn your vision into reality with our tailored, high-quality solutions.

---

### Reference links used

- [DisplayFeature — Flutter API docs](https://api.flutter.dev/flutter/dart-ui/DisplayFeature-class.html)
- [Proposal: populate MediaQuery.displayFeatures on iOS — flutter/flutter#192515](https://github.com/flutter/flutter/issues/192515)
- [PR: populate display features from the iPhone Duo hinge — flutter/flutter#193025](https://github.com/flutter/flutter/pull/193025)
- [PR: animate the child between sub-screens when the fold changes — flutter/flutter#192721](https://github.com/flutter/flutter/pull/192721)
- [Flutter app should adjust UI for half-open state — flutter/flutter#193034](https://github.com/flutter/flutter/issues/193034)
- [Keyboard dismissed on posture change — flutter/flutter#193096](https://github.com/flutter/flutter/issues/193096)
- [@FlutterDev — "We just checked, Flutter still runs everywhere"](https://x.com/FlutterDev/status/2103597923057775078)
- [Apple Newsroom — Apple unveils iPhone Duo](https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/)
- [Apple Tech Talk — Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/)
- [dual_screen on pub.dev](https://pub.dev/packages/dual_screen)
- [foldable on pub.dev](https://pub.dev/packages/foldable)
- [Flutter MediaQuery class docs](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- Internal link suggestion (Content Marketing): [Flutter 3.44 Migration Guide](https://somniosoftware.com/blog/flutter-3-44-migration-guide-agp-9-swift-package-manager-and-breaking-changes)

---

### Screenshots to include (Graphic Designer)

All files are in `duo-lab/findings/`. Three are enough, in this order:

1. `05-inner-half-open-inner.png`. `DISPLAYFEATURES: EMPTY` in red, directly above the `package:foldable` panel reporting `partiallyOpen` at 127.8°. Same device, same frame.
2. `18-hinge-demo-portrait-inner.png`. A layout that ignores the hinge next to one that reads the fold region, with the hinge band drawn in red across a paragraph in the first.
3. `17-inner-portrait-16-9-inner.png`. The 16:9 probe showing `61.8% unused height`.

---

### Verificaciones pendientes antes de publicar (no forman parte del artículo)

Afirmaciones sobre terceros que no salen del lab y conviene re-chequear el día que se publique, porque envejecen rápido: el estado de los dos PRs y de la propuesta #192515, que ningún PR de Duo haya mergeado, que stable siga en 3.47.5, la fecha del anuncio, las medidas de los paneles, que Split View sea nuevo en iPhone, el origen del embedder de Android, el estado de `dual_screen`, el post de @FlutterDev del 26 de septiembre, y que el repositorio de Wonderous no tenga commits especificos de plegables. Todas se verificaron el 28 de septiembre contra la API de GitHub y pub.dev.
