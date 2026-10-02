# iPhone Duo + Flutter — measured lab report

Measured 2026-09-21 on macOS 26.6.2 (25G83), Apple silicon.

| | |
|---|---|
| Xcode | 27.1 beta, build **27A9269** (installed side by side as `/Applications/Xcode-27.1-beta.app`) |
| Simulator runtime | iOS **27.1 (24A94401)** |
| Device | iPhone Duo, udid `AA16FBB4-F351-4AD9-BBF5-45562B10CFDD` |
| Flutter | **3.47.5** stable, rev `6a19cca564`, Dart 3.13.4, engine `af7e796e16` |
| Probe app | `duo_probe`, bundle id `com.example.duoProbe` |
| Extra package | `foldable` **1.0.4** |

Full environment capture, including the starting state of the machine and every
install step, is in `ENVIRONMENT.md`.

---

## How to read the numbers

- All sizes are **logical pixels (lp)** unless the column says `px`.
- Every row comes from a JSON file in this directory, written by the probe app
  itself. The **filename** identifies the condition, not the `condition` key
  inside the JSON.
- **Caveat on the `condition` key**: the harness pipes `flutter run` through
  `grep -v` before `tee`, and that grep block-buffers its output. `run.log`
  therefore lags the live app by up to a few KB, so the `condition` string
  embedded in some JSON files is one condition behind. The geometry in each
  file was cross-checked against the paired PNG screenshot and is correct.
  A rerun should insert `stdbuf -oL` in the pipeline.
- Overlay widths do **not** come from these JSON files. They come from the
  `Material` surface inside each overlay, read off the render tree, and are
  cross-checked against a `LayoutBuilder` printing its own `maxWidth`. Both
  are exact regardless of log lag. See Q7, including one measurement method
  that produced convincing wrong numbers and was discarded.
- `foldable` package readings come from `Foldable.snapshot`, logged on demand,
  not from the JSON files.

---

## The two screens, measured

| | logical | devicePixelRatio | physical (lp × dpr) | screenshot |
|---|---|---|---|---|
| Outer, portrait | **466 × 678** | 3.0 | 1398 × 2034 px | `01-outer-closed-portrait-outer.png` |
| Outer, landscape | **678 × 466** | 3.0 | 2034 × 1398 px | `02-outer-closed-landscape-outer.png` |
| Inner, landscape | **951 × 669** | 3.0 | 2853 × 2007 px | `04-inner-open-landscape-inner.png` |
| Inner, portrait | **669 × 951** | 3.0 | 2007 × 2853 px | `03-inner-open-portrait-inner.png` |

The inner screen's geometry is identical in all three postures — closed is the
only state that changes which panel you are on.

`xcrun simctl io <udid> enumerate` reports the Duo as having **two primary
displays**, `primary` (`LCD`) and `primary-1` (`LCD-1`). Screenshots must name
one with `--display=`, or only one is captured. Every condition below was
captured on both; the `-inner` / `-outer` suffix says which.

---

## Condition matrix

`features` is the length of `MediaQuery.of(context).displayFeatures`.

| # | Condition | size | dpr | pad L | pad T | pad R | pad B | features | orientation | file |
|---|---|---|---|---|---|---|---|---|---|---|
| 01 | Outer (closed), portrait | 466 × 678 | 3.0 | 0.0 | 0.0 | **84.0** | 34.0 | 0 | portrait | `01-outer-closed-portrait` |
| 02 | Outer (closed), landscape | 678 × 466 | 3.0 | **84.0** | 0.0 | 0.0 | 34.0 | 0 | landscape | `02-outer-closed-landscape` |
| 03 | Inner open, portrait | **669 × 951** | 3.0 | 0.0 | **82.0** | 0.0 | 34.0 | 0 | portrait | `03-inner-open-portrait` |
| 04 | Inner open, landscape | 951 × 669 | 3.0 | 0.0 | 0.0 | **84.0** | 34.0 | 0 | landscape | `04-inner-open-landscape` |
| 05 | Inner half open (book) | 951 × 669 | 3.0 | 0.0 | 0.0 | **84.0** | 34.0 | 0 | landscape | `05-inner-half-open` |
| 06 | Inner half open (tent) | — | — | — | — | — | — | — | — | **NOT AVAILABLE IN SIMULATOR** |
| 07 | Split View, 50% | **469 × 669** | 3.0 | 0.0 | 0.0 | **0.0** | 34.0 | 0 | **portrait** | `07-split-view-50` |
| 07b | Split View, 50%, unfocused | 469 × 669 | 3.0 | 0.0 | 0.0 | 0.0 | 34.0 | 0 | portrait | `07b-split-view-unfocused` |
| 08 | Split View, small pane | — | — | — | — | — | — | — | — | **NOT AVAILABLE — only 50/50 exists** |
| 09 | Inner open, keyboard up | 951 × 669 | 3.0 | 0.0 | 0.0 | 84.0 | **0.0** | 0 | landscape | `09-inner-keyboard` |
| 10 | Inner open, `AlertDialog` | 951 × 669 | 3.0 | 0.0 | 0.0 | 84.0 | 34.0 | 0 | landscape | `10-inner-dialog` |
| 11 | Inner open, `showDatePicker` | 951 × 669 | 3.0 | 0.0 | 0.0 | 84.0 | 34.0 | 0 | landscape | `11-inner-datepicker` |
| 12 | Inner open, `showModalBottomSheet` | 951 × 669 | 3.0 | 0.0 | 0.0 | 84.0 | 34.0 | 0 | landscape | `12-inner-bottomsheet` |

Extra conditions captured beyond the requested twelve:

| # | Condition | Note | file |
|---|---|---|---|
| 05b | Half open **with keyboard already up** | `viewInsets.bottom` collapsed 264.0 → 0.26 | `05-half-open-keyboard` |
| 13 | Inner open, 16:9 letterbox probe | 22.1% of height unused | `13-inner-layout-16-9` |
| 14 | Inner open, State tab before fold cycle | `StatePage instance #1` | `14-state-before-fold` |
| 15 | Inner open, State tab after full fold cycle | still `instance #1` | `15-state-after-fold` |
| 16 | App Switcher after crossing all three postures | preview undistorted | `16-app-switcher-after-pose-change.png` |
| 17 | Inner **portrait**, 16:9 letterbox probe | **61.8%** of height unused | `17-inner-portrait-16-9` |
| 18 | Inner portrait, hinge demo — naive vs fold-aware layout | the article's before/after image | `18-hinge-demo-portrait` |
| 19 | Inner portrait, each overlay measured | dialog 88.0%, picker 53.8%, sheet 95.7% | `19-dialog-portrait`, `19-datepicker-portrait`, `19-sheet-portrait` |
| 20 | Outer, four navigation widgets measured | all four fill 412.0 of 412.0 lp | `20-nav-bars-outer` |
| 21 | Inner open, four navigation widgets measured | all four fill 897.0 of 897.0 lp | `21-nav-bars-inner` |

In every single condition measured — both screens, both orientations, all
three postures, and Split View — `MediaQuery.displayFeatures` was `[]`.

Ten of the twelve requested conditions were measured. The two that were not
do not exist on this device: there is no control that distinguishes book from
tent (06), and Split View has no small-pane state (08).

`textScaler.scale(14)` was `14.0` and `platformBrightness` was `light` in every
condition. The root `LayoutBuilder` constraints matched `MediaQuery.sizeOf`
exactly (delta 0 × 0) in every condition — tight constraints, no discrepancy.

---

## The ten questions

### 1. How big is the inner screen in logical pixels? Does width exceed 600?

**951 × 669 lp in landscape, 669 × 951 lp in portrait. `devicePixelRatio` 3.0
in both.**

**Width exceeds 600 in either orientation.** 951 in landscape, 669 in
portrait. This is not a borderline case: any layout keyed on `width > 600`
takes the tablet branch on the inner screen no matter how the device is held,
and a shortest-side breakpoint does too, since the short side is 669.

The outer screen is **466 × 678 lp**, so its width is **below 600** in portrait
and above it in landscape (678). A `width > 600` test therefore flips purely on
how the closed device is held.

The one case that does drop below 600 on the inner screen is **Split View at
469 lp** — see conditions 07/08. So the same unfolded screen can serve you 951,
669 or 469 lp depending on orientation and multitasking, straddling the
breakpoint in both directions.

Screenshot: `04-inner-open-landscape-inner.png` — the probe prints
`WIDTH > 600 BREAKPOINT: YES` in green.

**Discrepancy against the published hardware spec.** The brief states the inner
panel is 1878 × 2670 px. Measured framebuffer is **2007 × 2853 px**:

| | brief | measured | ratio |
|---|---|---|---|
| Outer | 1398 × 2034 px | 1398 × 2034 px | 1.0000 — exact match |
| Inner | 1878 × 2670 px | 2007 × 2853 px | 1.0687 / 1.0685 |

The aspect ratio agrees to four decimals (0.7034 vs 0.7035), so this is a pure
scale difference, not a different panel shape. The outer screen matches the
published spec exactly, which argues the measurement method is sound and the
inner screen is the odd one.

A render-then-downsample pipeline would explain it: Flutter would be rendering
at 3.0× into a 2007 × 2853 buffer that the panel downsamples to its native
2670 tall, exactly as the iPhone Plus models did (render 1242 × 2208, display
1080 × 1920). That would make the **effective physical scale 2670 / 951 =
2.8076**, not the 3.0 Flutter reports.

`NO VERIFICADO`: I cannot confirm the downsampling hypothesis from a simulator.
What is measured is the framebuffer size and the reported `devicePixelRatio`.
Whether the shipping panel is 1878 × 2670 and downsamples, or the brief's
figure is wrong, is not decidable here.

### 2. Does `displayFeatures` ever return anything?

**No. Never. Not once.**

`[]` in all 12 measured conditions, on both displays, in closed, half-open and
fully-open postures — including while the `foldable` package was simultaneously
reporting an active fold region on the very same frame.

The probe prints this literally as `displayFeatures: [] (EMPTY)` in red.
Clearest screenshot: `05-inner-half-open-inner.png`, where the red
`DISPLAYFEATURES / EMPTY` tile sits directly above the `package:foldable` panel
reporting `status: partiallyOpen`, `angleDegrees: 127.77777862548828` and
`regions: 2`. Same device, same instant, same frame.

This confirms the documented behaviour (`"This is populated only on Android."`)
and confirms that flutter/flutter#193025 is indeed not in 3.47.5.

### 3. Is the padding asymmetric?

**Sometimes — and which side it lands on depends on orientation.** In three of
five states it is horizontally asymmetric; in two it is not.

| Condition | pad.left | pad.top | pad.right | pad.bottom | horizontally asymmetric |
|---|---|---|---|---|---|
| Outer portrait | 0.0 | 0.0 | **84.0** | 34.0 | **yes** |
| Outer landscape | **84.0** | 0.0 | 0.0 | 34.0 | **yes** |
| Inner landscape (all postures) | 0.0 | 0.0 | **84.0** | 34.0 | **yes** |
| Inner **portrait** | 0.0 | **82.0** | 0.0 | 34.0 | no — it moved to the top |
| Split View 50% | 0.0 | 0.0 | 0.0 | 34.0 | no — no inset at all |

So the honest answer is not "always asymmetric". It is: **there is a single
large inset that migrates around the frame as the device rotates**, and it
lands on a horizontal edge in three of the five states.

The inset tracks a physical feature, not a logical side. Rotating the outer
screen moved all 84 lp from right to left. Rotating the inner screen to
portrait moved it off the horizontal axis entirely and turned it into an 82 lp
**top** inset. `viewPadding` carries the same values, so these are safe-area
insets, not transient ones.

`EdgeInsets.symmetric(horizontal: …)` is wrong in the three landscape-ish
states and harmless in the other two — which is worse than being wrong
everywhere, because it will pass a casual test in exactly the orientation a
developer is most likely to try first.

**What the inset actually is, and how much it wastes.** The `foldable` package
gives the real rectangle, and it is far smaller than the reserved strip:

| Condition | occlusion rect | real size | `MediaQuery` charges | wasted |
|---|---|---|---|---|
| Inner landscape | `867.0, 0.0 → 951.0, 120.0` | 84 × 120 | 84 lp × full 669 height | 84 × 549 = **46,116 lp²** |
| Inner portrait | `535.0, 0.0 → 669.0, 82.0` | 134 × 82 | 82 lp × full 669 width | 535 × 82 = **43,870 lp²** |
| Outer portrait | `382.0, 0.0 → 466.0, 170.0` | 84 × 170 | 84 lp × full 678 height | 84 × 508 = **42,672 lp²** |

In every case the obstruction is a corner cutout, and `MediaQuery.padding`
conservatively reserves its width or height across the *entire* opposite
dimension. Note the numbers line up exactly: 951 − 867 = 84 = `padding.right`;
the portrait occlusion is 82 tall = `padding.top`.

Screenshots: `01-outer-closed-portrait-inner.png`,
`02-outer-closed-landscape-inner.png`, `03-inner-open-portrait-inner.png`,
`04-inner-open-landscape-inner.png` — the probe's padding diagram draws all
four values in position and turns the box red when `left != right`.

### 4. What `AppLifecycleState` does the app get in Split View when visible but unfocused?

**It stays `resumed`. No event fires at all.** This is the reassuring answer:
an app that pauses video or timers on `inactive` will **not** pause while
sitting visible beside another app.

Measured sequence, from the probe's `didChangeAppLifecycleState` log:

| Time | Event | What was happening |
|---|---|---|
| 14:42:37.855 | `inactive` | entering Split View |
| 14:42:39.485 | `resumed` | settled in Split View, focused |
| — | *(nothing)* | **user tapped the other app; duo_probe visible, unfocused** |
| 14:45:26.378 | `inactive` | duo_probe dismissed out of Split View |
| 14:45:26.783 | `hidden` | " |
| 14:45:26.784 | `paused` | " |

Losing focus while staying visible produced **no lifecycle event whatsoever**.
The last state remained `resumed`, timestamped from when Split View was
entered. The command channel was still being serviced at that moment, which
independently confirms the app was running rather than suspended.

Being actually removed from view produced the full `inactive` → `hidden` →
`paused` sequence within 0.4 s. So the framework does distinguish the two
cases correctly.

Related measurement: during a full fold cycle (half-open → closed → fully
open), which moves the app between two physical displays and blanks the screen
for several seconds, the app received **zero** `AppLifecycleState`
transitions. See Q5.

### 5. What happens to state when folding and unfolding?

**Everything is preserved. Nothing is recreated.**

Traced across the full cycle, from the probe's own `initState` / `dispose`
instrumentation:

| Step | size | orientation | `rootBuilds` | `StatePage` instance |
|---|---|---|---|---|
| Half open | 951 × 669 | landscape | 4 | #1 |
| **Closed** | **466 × 678** | **portrait** | **4** | #1 |
| Fully open | 951 × 669 | landscape | 4 | #1 |

- `StatePage.initState` fired **once**, at app start. No second call.
- `StatePage.dispose` **never** fired.
- `App.initState` fired once. The app does not restart.
- **`rootBuilds` never moved off 4.** The root `build()` did not re-run at all;
  the entire posture change was absorbed inside the `LayoutBuilder` /
  `MediaQuery` subtree below it.
- No `AppLifecycleState` transition, as noted in Q4.

Evidence in the UI as well: `16-app-switcher-after-pose-change.png`, taken
after the app had crossed all three postures, shows
`StatePage instances created: 1` and the green `instance #1` pill.

So: no rebuild of the root, no `State` recreation, no app restart. This is the
good news of the whole lab. The flip side is Q2 and Q4 — nothing is destroyed,
but nothing tells you the fold happened either.

### 6. Do the navigation bars fill the width on the inner screen? Where is the FAB?

**Yes, `BottomNavigationBar` spans the full 951 lp.**

In `13-inner-layout-16-9-inner.png` the four items are evenly distributed
across the whole width and the bar's background reaches both edges. The FAB
sits at its normal `endFloat`-adjacent position above the bar, inside the safe
area, to the left of the 84 lp occlusion — it is not clipped by the cutout.

**And so do the other three navigation widgets.** Issue #193035 is described as
a *tab bar*, which in Flutter is `TabBar` — a different widget from
`BottomNavigationBar`. To close that gap, all four candidates were rendered
side by side at full available width and each was asked, from the render tree,
how wide it actually ended up:

| Widget | inner screen, 897.0 lp available | outer screen, 412.0 lp available |
|---|---|---|
| `TabBar` inside an `AppBar` | **897.0 × 48.0** — fills | **412.0 × 48.0** — fills |
| `TabBar` bare | **897.0 × 48.0** — fills | **412.0 × 48.0** — fills |
| `NavigationBar` (Material 3) | **897.0 × 80.0** — fills | **412.0 × 80.0** — fills |
| `BottomNavigationBar` (fixed, 4 items) | **897.0 × 58.0** — fills | **412.0 × 58.0** — fills |

`fillsAvailable` was `true` for all eight measurements. Not one of the four
widgets came up short, on either display.

Screenshot: `21-nav-bars-inner-inner.png` (inner, 951 lp) and
`20-nav-bars-outer-inner.png` (outer, 466 lp). Source:
`duo_probe/lib/nav_bars.dart`.

**#193035 did not reproduce with any of the four widgets in this
configuration.** That is a stronger statement than the earlier draft could
make, but it is still scoped: four items each, default theming, no constrained
parent, inner and outer screens, fully-open posture. It does not prove the
issue is invalid — only that the plain case is fine.

One visual detail worth a second look if the article goes deep: in the
`AppBar`-wrapped `TabBar`, the divider line under the tabs appears to stop
short of the right edge, while the bare `TabBar`'s divider runs the full
width. The measured widget box is 897.0 in both cases, so this is an internal
decoration and not a layout failure — **not investigated further**.

### 7. Do the dialog / date picker / bottom sheet confine themselves?

**Yes. All three. None uses the full width, and the date picker uses barely
half.** On the inner screen, 951.0 lp wide:

| Overlay | painted surface | share of width | cross-check |
|---|---|---|---|
| `AlertDialog` (with a 4000 lp wide child) | **787.0 × 288.0 lp** | **82.8%** | content `LayoutBuilder` reads 739.0 = 787 − 24 padding each side ✓ |
| `showDatePicker` | **496.0 × 346.0 lp** | **52.2%** | internal panes 152.0 + 344.0 = 496.0 ✓ |
| `showModalBottomSheet` | **640.0 × 240.0 lp** | **67.3%** | content `LayoutBuilder` reads 640.0 ✓ |

Each figure was obtained two independent ways and they agree.

The `AlertDialog` figure is the strongest evidence of a hard ceiling: its
content was an explicit `SizedBox(width: 4000)`, so 787.0 is imposed by the
framework's dialog sizing, not by the content asking for less.

`showDatePicker` is the most confined of the three — on a 951 lp screen it
paints 496 lp, barely over half.

The same three, measured again with the inner screen in **portrait**, 669.0 lp
wide:

| Overlay | painted surface | share of width |
|---|---|---|
| `AlertDialog` | **589.0 × 288.0 lp** | **88.0%** |
| `showDatePicker` | **360.0 × 336.0 lp** | **53.8%** |
| `showModalBottomSheet` | **640.0 × 240.0 lp** | **95.7%** |

Two things fall out of comparing the two orientations:

**The bottom sheet is capped at exactly 640.0 lp, not at a percentage.**
Identical absolute width in both orientations — 67.3% of a 951 lp screen,
95.7% of a 669 lp one. That is Material's max sheet width, and it means the
sheet will never widen past 640 no matter how much screen the Duo offers.

**The date picker holds near half the width in both** — 52.2% landscape,
53.8% portrait — but changes shape entirely: landscape it is the two-pane
layout (152 + 344 = 496), portrait it is the single stacked column at 360.

For reference, the same date picker on the **outer** screen measured
**350.0 × 568.0 lp** of a 466.0 lp screen = **75.1%**.

**A measurement that was discarded.** A first pass read the `renderObject` of
the `Dialog` / `AlertDialog` / `DatePickerDialog` elements directly and got
867.0 × 635.0 for every one of them. That is not the dialog: 951 − 84 = 867
and 669 − 34 = 635, i.e. it is the safe-area layout slot the route is given.
Those numbers are wrong as dialog widths and are not used anywhere in this
report. The figures in the table above come from the `Material` surface inside
each overlay, which does match the painted result.

Screenshots: `10-inner-dialog-inner.png`, `11-inner-datepicker-inner.png`,
`12-inner-bottomsheet-inner.png`. The sheet renders its own measurement on
itself — `640.0 / 951.0 lp`, `67.3% of screen width`.

### 8. Is `SystemChrome.setPreferredOrientations([portraitUp])` respected on the inner screen?

**No on the inner screen. Yes on the outer screen.** This is a clean split.

**Important correction.** An earlier pass of this report claimed the inner
screen was landscape-locked and that condition 03 was unreachable. **That was
wrong.** The operator reached inner portrait through the simulator UI, and it
was then measured in full (669 × 951, condition 03). The inner screen rotates
perfectly well.

What is true is narrower and more interesting: **the device rotates, but the
app cannot ask it to.** With the inner screen in portrait, calling
`setPreferredOrientations([landscapeLeft, landscapeRight])` left it at
669 × 951 portrait. With it in landscape, requesting `[portraitUp]` left it at
951 × 669 landscape. The API is ignored in **both** directions on the inner
screen, while being honoured on the outer one.

**Outer screen — respected.** Calling
`setPreferredOrientations([landscapeLeft, landscapeRight])` rotated it from
466 × 678 portrait to 678 × 466 landscape, and the 84 lp inset moved from the
right edge to the left edge. The call took effect.

**Inner screen — ignored.** With the device fully open at 951 × 669 landscape,
`setPreferredOrientations([DeviceOrientation.portraitUp])`:

- the call fired and completed (logged:
  `setPreferredOrientations portrait -> [DeviceOrientation.portraitUp]`)
- `didChangeMetrics` did **not** fire
- `MediaQuery.sizeOf` stayed `951 × 669`
- `MediaQuery.orientationOf` stayed `landscape`
- the framebuffer stayed 2853 × 2007 px

Symmetrically, with the inner screen in portrait at 669 × 951, requesting
`[landscapeLeft, landscapeRight]` also did nothing — same size, same
orientation, same padding afterwards.

Rotation methods tried against the inner screen:

| Method | Result |
|---|---|
| `SystemChrome.setPreferredOrientations([portraitUp])` from landscape | no effect |
| `SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])` from portrait | no effect |
| DeviceHub → Device → Orientation → Portrait | no effect |
| DeviceHub → Controls → Rotate Left / Rotate Right | no effect |
| `xcrun simctl io <udid> screenConfig --display=primary-1 geometry 2007x2853` | prints `Screen 3 geometry set to 2007x2853 (scale 3.0)`, framebuffer unchanged, app unchanged |
| **Operator, through the simulator UI** | **works — this is how condition 03 was reached** |

`NO VERIFICADO`: the exact UI affordance the operator used was not recorded, so
the reproducible click path for rotating the inner screen is not documented
here. What is established is that rotation is possible and that none of the
four programmatic paths above achieve it.

The practical consequence for app authors is the same either way: **on the
inner screen, orientation is the user's and the system's to decide, and
`setPreferredOrientations` does not participate.** An app that relies on
locking orientation will silently not be locked there, while the identical
call works on the outer screen of the same device.

### 9. How much does a 16:9 `AspectRatio` letterbox on the inner screen?

**22.1% in landscape. 61.8% in portrait.**

| Orientation | 16:9 box | screen height | unused height |
|---|---|---|---|
| Inner landscape | 927.0 × 521.4 lp | 669.0 | 147.6 lp → **22.1%** |
| Inner portrait | 645.0 × 362.8 lp | 951.0 | 588.2 lp → **61.8%** |

The cause is the inner screen's aspect ratio. Landscape it is 951 / 669 =
**1.42** against the 1.78 that 16:9 wants — a much squarer screen than a phone
in landscape, so full-width 16:9 leaves a real band. Portrait it is 0.70, and
a full-width 16:9 box occupies barely over a third of the height.

**Nearly two thirds of the tallest iPhone screen ever shipped goes to letterbox
for a full-width 16:9 video in portrait.** Any video-first app that places a
16:9 player at the top and content below will find the player looking small
relative to a very large empty area, or will need a non-16:9 presentation.

The probe computes and renders this live. Screenshots:
`13-inner-layout-16-9-inner.png` (landscape, `22.1% unused height`) and
`17-inner-portrait-16-9-inner.png` (portrait, `61.8% unused height`).

### 10. Do the reported bugs reproduce?

| Issue | Verdict | Evidence |
|---|---|---|
| **#193096** keyboard disappears on posture change | **YES — reproduced** | measured |
| **#193078** distorted App Switcher preview after posture change | **NO — not reproduced** | `16-app-switcher-after-pose-change.png` |
| **#193088** flickering while folding | **PARTIAL — see below** | operator observation |
| **#193035** tab bar does not fill the width | **NO — not reproduced, all 4 nav widgets** | `21-nav-bars-inner-inner.png` |
| **#193034** half-open not distinguishable | **YES — reproduced** | see below |

**#193096 — reproduced, with numbers.** With the software keyboard up on the
inner screen, `viewInsets.bottom` measured **264.0** (and `padding.bottom`
collapsed from 34.0 to 0.0, the home indicator inset being absorbed). The
posture was then changed to half-open with the keyboard still up. Immediately
after: **`viewInsets.bottom = 0.2609`** — effectively zero. The keyboard was
dismissed by the posture change, and the app's layout snapped back. Files:
`09-inner-keyboard.json` (before, 264.0) and `05-half-open-keyboard.json`
(after, 0.26).

**#193078 — not reproduced.** After the app had crossed closed, half-open and
fully-open, the App Switcher preview rendered with the correct aspect ratio
(~1.42, matching 951 × 669), full content, no stretching and no clipping.

**#193088 — partial, and the observation is the operator's, not an
instrumented measurement.** The operator reported: *no flash or flicker, but
the screen goes black for a few seconds* during the transition. I did not
instrument the blackout duration, and the `didChangeMetrics` timestamps around
the fold are dominated by the operator's own click timing, so no duration can
be extracted from them. Reported as a qualitative observation only. `NO
VERIFICADO` as a number.

**#193034 — reproduced.** Half-open is completely indistinguishable from fully
open through Flutter's own APIs. Every value the framework exposes was
byte-identical between the two postures: size 951 × 669, padding
L0/T0/R84/B34, `viewInsets` all zero, `viewPadding` R84/B34, orientation
landscape, `displayFeatures` `[]`, root constraints 951 × 669. Compare
`04-inner-open-landscape.json` against `05-inner-half-open.json` — the geometry
sections are the same. Meanwhile the `foldable` package, on the same device at
the same moment, reported `partiallyOpen` at 127.78°.

---

## Split View — conditions 07 and 08

**Split View works on the iPhone Duo, and it works with a stock Flutter app.**

I predicted it would not, because `flutter create` emits
`UIApplicationSupportsMultipleScenes = false` and iPadOS-style multitasking
normally requires multiple scene support. **That prediction was wrong.** The
flag is still `false` in the app that entered Split View — verified in
`ios/Runner/Info.plist` at the time of the test. No multitasking button (`•••`
or similar) appears anywhere in the app's chrome; Split View is entered
through device gestures instead.

### Condition 07 — Split View at 50%

| | value |
|---|---|
| size | **469.0 × 669.0 lp** |
| `devicePixelRatio` | 3.0 |
| padding | L 0.0, T 0.0, **R 0.0**, B 34.0 — **symmetric** |
| `viewInsets` | all zero |
| `displayFeatures` | `[]` |
| orientation | **portrait** |
| root constraints | 469.0 × 669.0, tight |
| lifecycle | `resumed` |

Three things worth pulling out:

**The 84 lp inset vanishes.** This is the only condition in the entire lab
where `padding.left == padding.right`. The app's pane sits on the half of the
screen away from the camera cutout, so it inherits no horizontal inset at all.
A layout that was fighting an 84 lp asymmetry a moment ago now has none — and
will get it back the moment the user leaves Split View.

**The 600 breakpoint flips.** 469 < 600. The same app, on the same unfolded
951 lp screen, drops from its tablet branch to its phone branch purely because
a second app appeared. `MediaQuery.orientationOf` also flips to `portrait`,
because the pane is taller than it is wide.

**The app's pane contains part of the hinge, and only `foldable` says so.**
The fold band is at 455.5–495.5 in full-screen coordinates; the pane ends at
469. The package re-expresses the region in pane coordinates as
`division: Rect.fromLTRB(455.5, 0.0, 469.0, 669.0)`, i.e. **13.5 lp of hinge
running down the pane's right edge**. `MediaQuery.displayFeatures` is `[]`,
as always.

`horizontalSizeClass` also changed from `regular` to **`compact`** — the
package tracks Split View, not just the fold.

### Condition 08 — Split View, small pane

**NOT AVAILABLE. The iPhone Duo's Split View is 50/50 only.**

Attempting to drag the divider to make `duo_probe` the smaller pane does not
produce a smaller pane. There is no 1/3 ↔ 2/3 snap position. Dragging past the
midpoint dismisses the app entirely and hands the full screen to the other
app — which is what produced the `inactive` → `hidden` → `paused` sequence
recorded in Q4. Operator's description after repeated attempts: *"No engancha,
es siempre 50%."*

So there is no small-pane condition to measure on this device, and the
narrowest width a Flutter app can be asked to render at on the inner screen is
**469 lp**.

---

## Step 4 — `package:foldable` 1.0.4

Published 2026-09-20, iOS-only. Added with `flutter pub add foldable`, no other
configuration.

**It works in the simulator. No physical hardware is required.**

Full snapshot taken with the device half-open, via `Foldable.snapshot`:

```
isFoldable        = true
status            = partiallyOpen
angleDegrees      = 127.77777862548828
horizontalSizeClass = regular
verticalSizeClass   = regular
supportLevel      = available
hingeApiPresent   = true
regionApiPresent  = true
angleUnitVerified = true
strategy          = updateHandler
regions           = [
  division:  Rect.fromLTRB(455.5, 0.0, 495.5, 669.0)  active=true
  occlusion: Rect.fromLTRB(867.0, 0.0, 951.0, 120.0)  active=true
]
bridgedFeatures   = 0
```

Read against the same frame where `MediaQuery.displayFeatures` was `[]`:

- **It reports the posture.** `partiallyOpen`, the state Flutter cannot see.
- **It reports the hinge angle**, 127.78°, with `angleUnitVerified = true`.
- **It reports the fold geometry.** The `division` region is a band
  **455.5 → 495.5**, i.e. **40 lp wide, spanning the full 669 lp height**. The
  screen is 951 wide, so its centre is 475.5 — the exact centre of the screen.
  Content placed there sits on the hinge.
- **It reports the cutout geometry.** The `occlusion` region is
  867 → 951 × 0 → 120, i.e. **84 × 120 lp**. Its width is exactly the
  `MediaQuery.padding.right` value of 84.0, but it is only 120 lp tall rather
  than the full height that `MediaQuery` reserves.
- **It reports iOS size classes**, `regular` / `regular`, which
  `MediaQuery` does not expose at all.
- `bridgedFeatures = 0`: the package's optional bridge into
  `MediaQuery.displayFeatures` is off by default, so it does not change the
  `[]` result unless explicitly enabled.

### The same package across all four device states

| State | `status` | `angle` | hSizeClass | regions |
|---|---|---|---|---|
| Closed (outer screen) | `closed` | **0.0** | `compact` | `occlusion 399.7,29.3→436.7,66.3` active; `occlusion 382.0,0.0→466.0,170.0` active |
| Half open | `partiallyOpen` | **127.77777862548828** | `regular` | `division 455.5,0.0→495.5,669.0` **active**; `occlusion 867.0,0.0→951.0,120.0` active |
| Fully open | `fullyOpen` | **180.0** | `regular` | `division 455.5,0.0→495.5,669.0` **inactive**; `occlusion 867.0,0.0→951.0,120.0` active |
| Split View 50% | `fullyOpen` | 180.0 | **`compact`** | `division 455.5,0.0→469.0,669.0` inactive |

`MediaQuery.displayFeatures` was `[]` for every row of that table.

Details worth noting:

- The `division` region is reported **even when the device is flat**, flagged
  `active: false`. So the fold's location is available for layout planning
  before the user ever bends the device.
- Closed, there is **no `division` region at all** — correct, the outer screen
  has no fold across it — but there are **two** occlusions: a 37 × 37 lp square
  at (399.7, 29.3) which is the camera lens, and an 84 × 170 lp block. That
  84 is the same number as `MediaQuery.padding.right` on the outer screen.
- In Split View the region is clipped and re-expressed in the pane's own
  coordinate space, and the size class drops to `compact`.

### `Foldable.debugDumpNativeApi()`

This dumps the Objective-C runtime shape of the private hinge API. It failed
to produce output on a first attempt; on a later run it worked. Full output is
saved as `foldable-native-api-dump.txt`. What it reveals:

```
UIHinge
  superclass: NSObject
  protocols:  BSDescriptionStreaming, NSCopying
  properties: status, angle
  methods:    status, angle, copyWithZone:, isEqual:, hash, init, …

UIHingeInteraction
  methods:    initWithUpdateHandler:
              setEnabled: / isEnabled
              willMoveToView: / didMoveToView:
              wantsCurrentHingeStateOnRegistration
              sceneHingeStateClientComponent:didUpdateFromHingeState:toHingeState:
              _updateForSceneHingeState:
              _windowWillMoveToNilScene:
              view

UIHingeInteractionDelegate  -> null (not a resolvable ObjC class)
UIHingeState                -> null
UIReservedRegion            -> null

uidevicehingeSelectors: []   (UIDevice exposes nothing hinge-related)
```

`UIHingeInteraction` is a `UIInteraction` attached to a `UIView`, constructed
with an update handler and driven by
`sceneHingeStateClientComponent:didUpdateFromHingeState:toHingeState:`. That is
precisely the hook a Flutter embedder would need to attach to its
`FlutterView` in order to populate `displayFeatures`. `UIDevice` offers no
shortcut — the empty selector list rules that path out.

Per the brief: no recommendation and no criticism, only the measurements above.

---

## The hinge demo — what actually breaks

Everything above is numbers. This is the picture. Screenshot:
`18-hinge-demo-portrait-inner.png`, source in `duo_probe/lib/hinge_demo.dart`.

The page renders two layouts one above the other, plus a red band drawn at the
exact `division` rectangle `foldable` reports, in screen coordinates.

**Top — the naive layout.** A `Row` (landscape) or `Column` (portrait) of two
`Expanded` panes with a centred divider, and an ordinary paragraph of running
text. Written the way anyone writes it. The red hinge band cuts straight
across two lines of the paragraph and lands on the divider. Nothing in the
code is wrong by Flutter's standards; `displayFeatures` is `[]`, so the
framework never gave the layout anything to react to.

**Bottom — the fold-aware layout.** Identical structure, except the split
reserves a gutter exactly as wide (or tall) as the reported `division` region,
so the seam falls in empty space and the text flows around it.

The difference between the two is reading the fold rectangle from
`package:foldable` instead of `MediaQuery.displayFeatures`. That is the whole
change.

The demo is deliberately **not** in the `BottomNavigationBar`, which stays at
four items so the #193035 measurement in Q6 remains valid. It is reached with
`lab.sh do tab/4`.

---

## Tooling findings

These are not about Flutter, but they determine whether any of this can be
automated, so they matter for anyone trying to reproduce the lab.

**Xcode 27 has no `Simulator.app`.** It does not exist in the Xcode 27.0 bundle
or the 27.1 beta bundle, nor anywhere else on the machine. It is replaced by
**DeviceHub.app**, at
`/Applications/Xcode-27.1-beta.app/Contents/Applications/DeviceHub.app`.

**The iPhone Duo requires the iOS 27.1 runtime exactly.** Creating the device
against iOS 27.0 fails outright:

```
An error was encountered processing the command (domain=com.apple.CoreSimulator.SimError, code=403):
Incompatible device
Unable to create a device for device type: iPhone Duo (com.apple.CoreSimulator.SimDeviceType.iPhone-Duo), runtime: iOS 27.0 (27.0 - 24A434) - com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

**The iOS 27.1 runtime is not available over the CLI.**
`xcodebuild -downloadPlatform iOS -buildVersion 27.1` answers
`iOS 27.1 is not available for download.` It has to be fetched through Xcode
27.1 beta's Settings → Components.

**There is no CLI for posture or rotation.** Checked against the complete
`simctl` subcommand list. `simctl ui` exposes only `appearance`,
`increase_contrast` and similar. There is no `pose`, `fold`, `hinge` or
`orientation` subcommand, and `device.plist` holds no posture key. The hinge
posture can only be set by clicking one of three buttons in DeviceHub's bottom
toolbar. **Automated posture testing of the iPhone Duo is not possible today.**

**`simctl io screenConfig` exists but does not substitute.**
`power off` on the inner display does not move the app to the outer display —
it just blanks the screen, and in this session it took SpringBoard down with it
(`The system shell (SpringBoard:18688) probably crashed`), requiring a reboot
of the simulator. `geometry` accepts a rotated size and prints success, but the
framebuffer does not change.

**DeviceHub owns the simulator lifecycle.** Quitting DeviceHub shut down the
booted simulator and killed the `flutter run` session.

**DeviceHub's menu bar goes stale.** Mid-session, with the device demonstrably
booted and the app running, the Device menu switched `Restart` to `Start` and
dropped the `Orientation` submenu entirely. Restarting DeviceHub restored it.
Any accessibility-driven automation has to detect this rather than trust the
menu.

**Flutter 3.47.5 generates a `SceneDelegate`, which silently breaks custom
scheme deep links.** With `enable-uiscene-migration` active, `flutter create`
emits `ios/Runner/SceneDelegate.swift` subclassing `FlutterSceneDelegate`, and
`Info.plist` points `UISceneDelegateClassName` at it. Setting
`FlutterDeepLinkingEnabled = true` and registering a `CFBundleURLTypes` scheme
is then **not enough**: `xcrun simctl openurl` succeeds, the app comes forward,
and nothing reaches Dart. The scene-based entry point is
`scene(_:openURLContexts:)`, which `FlutterSceneDelegate` does not forward to
the navigation channel. A freshly created 3.47.5 app does not receive custom
scheme deep links without hand-writing that override.

The harness therefore drives the app through a file in its own sandbox
(`Directory.systemTemp`, polled every 400 ms), reachable from the host via
`xcrun simctl get_app_container <udid> com.example.duoProbe data`. No plugin,
no Swift, no GUI focus.

**`UIApplicationSupportsMultipleScenes` is `false` in the stock template**,
which is the likely reason Split View could not be entered — see below.

---

## What I could NOT verify

Listed plainly, with the reason. No guesses filled in.

1. **Condition 08, Split View small pane.** No such state exists on this
   device — the divider offers 50/50 or dismissal, nothing between. This is a
   measured absence, not a gap in the testing.

2. **The reproducible click path for rotating the inner screen.** Portrait was
   reached and fully measured (condition 03), but the operator found the
   affordance by hand and the exact steps were not recorded. All four
   programmatic paths remain ineffective (Q8).

3. **Condition 06, tent posture.** DeviceHub exposes exactly three posture
   buttons — closed, half-open, fully open. Book and tent are the same
   half-open state as far as the simulator is concerned; there is no control
   that distinguishes them. Marked NOT AVAILABLE IN SIMULATOR rather than
   guessed.

4. **#193088 blackout duration.** Operator observed a multi-second black
   screen with no flicker. Not instrumented, so no figure. The
   `didChangeMetrics` timestamps around the fold are dominated by the
   operator's own click timing and cannot be used to derive it.

5. **The inner panel's true native resolution.** Measured framebuffer is
   2007 × 2853 px against a published 1878 × 2670. The downsampling explanation
   fits the numbers but cannot be confirmed from a simulator.

6. **Why `Foldable.debugDumpNativeApi()` failed the first time.** It produced
   no output on one run and full output on a later one, with no deliberate
   change in between. The output is captured; the flakiness is unexplained.

7. **Whether Split View behaves the same with
   `UIApplicationSupportsMultipleScenes = true`.** Split View was verified to
   work with the stock `false`, so there was no need to flip it. Whether
   enabling it changes pane sizing, adds the missing small-pane state, or
   changes anything at all was not tested.

8. **Whether any of this matches shipping hardware.** Everything here is the
   iOS 27.1 **beta** simulator on Xcode 27.1 **beta**, measured a month before
   the device ships on 2026-10-23. No physical iPhone Duo was involved.

9. **Anything requiring a second app's behaviour.** The Split View partner app
   was whatever the operator picked; its identity was not recorded and its
   effect on pane sizing was not isolated.

---

## Surprises

Things that stood out and were not on the question list.

**The inset is a corner cutout charged as a full-edge margin, in every
orientation.** `foldable` puts the inner-landscape occlusion at 84 × 120 lp;
`MediaQuery.padding` reserves 84 lp down all 669 lp of height. Rotate to
portrait and it becomes a 134 × 82 cutout charged as 82 lp across all 669 lp
of width. Either way roughly **44,000 lp² of perfectly usable screen** that a
`SafeArea`-based layout will never touch — on the device whose entire selling
point is more screen.

**The asymmetry disappears in portrait, which is worse than if it never
did.** Inner landscape has `padding.right: 84` and `left: 0`. Inner portrait
has both at `0` and the inset on top instead. A developer who tests
`EdgeInsets.symmetric(horizontal:)` in inner portrait sees nothing wrong and
ships the bug.

**The fold rotates with the device and stays dead centre.** Landscape:
`division 455.5, 0.0 → 495.5, 669.0`, a vertical 40 lp band. Portrait:
`division 0.0, 455.5 → 669.0, 495.5`, a horizontal 40 lp band. Same 455.5 and
495.5 both times, because it is the same physical hinge — but a layout that
avoided a vertical seam now has a horizontal one cutting across it.

**The root `build()` never runs on a posture change.** `rootBuilds` stayed at 4
while the app moved between two physically different displays, twice. Anything
hanging off the root widget's `build` — a size-dependent computation, a cached
layout decision, an analytics event — will simply not fire. Only descendants of
the `LayoutBuilder` and `MediaQuery` see it.

**The app crosses between two physical screens with zero lifecycle signal.**
Not `inactive`, not `paused`, nothing, despite the screen being black for
seconds. Combined with `displayFeatures` being empty, Flutter has *no*
first-party channel — not layout, not lifecycle — through which an app can
learn that the device folded.

**The fold band is 40 lp wide and always dead centre.** A two-column layout
that splits at 50% puts its divider exactly on the hinge; a centred FAB, a
centred dialog button, or a centred logo lands on it too. Nothing in Flutter
warns you.

**The outer screen matches the published spec exactly and the inner does not.**
Same measurement method, same session, same `devicePixelRatio`. That asymmetry
is what makes the inner-screen discrepancy interesting rather than dismissible
as measurement error.

**The half-open posture is a complete blind spot, but the data exists.** The OS
knows the angle to eight decimal places — 127.77777862548828 — and iOS exposes
it through `UIHingeInteraction`. It reaches `UIKit`. It just never crosses into
Flutter's `MediaQuery`. The gap is the embedder, not the platform.

**Two displays mean screenshots silently lie.** `xcrun simctl io <udid>
screenshot` without `--display=` captures one screen and says nothing about the
other. Early in this lab that produced a screenshot of an idle home screen
while the app was running, visible, on the other panel.

**Split View makes the padding symmetric — temporarily.** Condition 07 is the
only measurement in the whole lab where `padding.left == padding.right`. An
app that finally got its asymmetric-inset handling right will see that
asymmetry disappear and come back as the user enters and leaves Split View.
Layout code has to tolerate both, on the same screen, seconds apart.

**Split View pushes the app *below* the tablet breakpoint on the big screen.**
469 lp. The unfolded Duo is the widest iPhone screen ever shipped, and putting
a second app next to it drops your layout into its phone branch. Device size
and available width have come apart completely.

**Half of a fold can land inside your pane.** In Split View the `division`
region clips to `455.5 → 469.0` — 13.5 lp of hinge along the pane's right
edge. A pane that looks like an ordinary narrow phone layout still has
hardware running down one side of it.

**`setPreferredOrientations` works on one screen of the device and not the
other.** The same API call, in the same app, in the same session: honoured on
the outer screen, silently ignored on the inner one. No error, no exception,
no `didChangeMetrics` — it simply does nothing.

**The date picker is the worst offender on width.** 496 lp painted on a 951 lp
screen — 52.2%. The `AlertDialog` manages 82.8% and the bottom sheet 67.3%.
On the outer screen the same picker takes 75.1%. It gets proportionally
*narrower* as the screen gets bigger.

**Measuring a dialog's `renderObject` gives you the safe area, not the
dialog.** Every dialog type returned exactly 867 × 635 — which is
951 − 84 by 669 − 34. A plausible-looking number that is entirely wrong.
Anyone instrumenting overlay widths on this device should measure the
`Material` surface, and should sanity-check any width that happens to equal
the screen minus the insets.

---

## Files

| File | Contents |
|---|---|
| `ENVIRONMENT.md` | Machine starting state, every install step, verbatim command output |
| `REPORT.md` | This file |
| `run.log` | Full `[DUO_PROBE]` instrumentation log, current session |
| `run-part1.log` | Same, earlier session before an app restart (750 lines) |
| `NN-*-inner.png` | Screenshot of the **inner** display for that condition |
| `NN-*-outer.png` | Screenshot of the **outer** display for that condition |
| `NN-*.json` | Full metric snapshot for that condition |
| `16-app-switcher-after-pose-change.png` | Operator-captured App Switcher evidence for #193078 |
| `foldable-native-api-dump.txt` | Full `Foldable.debugDumpNativeApi()` output — the Objective-C shape of `UIHinge` and `UIHingeInteraction` |
| `REQUESTS.md` | What this lab can still measure on request, numbered R1–R14, with the cost of each |

Harness, reusable:

| File | Purpose |
|---|---|
| `../lab.sh` | `pose` / `do` / `capture` — drives the device and records a condition |
| `../duo_probe/` | The probe app |
| `../mise.toml` | Pins Flutter 3.47.5 to this directory only |
