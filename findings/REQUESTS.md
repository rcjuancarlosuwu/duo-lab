# What this lab can still measure, on request

For whoever is writing the article. The harness is intact and the simulator
can be brought back up in about two minutes, so anything below can be turned
into a real measurement rather than an assumption. Each item lists what you
would get and what it costs, including how many manual clicks the operator has
to make, since posture and rotation have no CLI.

Ask for these by number.

---

## Cheap — no manual clicks, CLI only

**R1. Any condition re-measured with a different widget.**
The probe app is a measuring instrument, not a fixed script. Any Flutter
widget can be dropped into it and measured under every condition already in
the matrix. Cost: ~10 min per widget.

**R2. ~~`TabBar`, `NavigationBar` and `NavigationRail` — the #193035 gap.~~**
**CLOSED 2026-09-28.** All four navigation widgets were measured on both
screens; every one fills its available width. See Q6 in `REPORT.md` and
`duo_probe/lib/nav_bars.dart`. `NavigationRail` was not tested — it is a
side rail, not a bar, and does not match the issue's description.

**R3. Text and font scaling.**
Every condition was measured at `textScaler.scale(14) == 14.0`, i.e. default.
Larger accessibility sizes on a 40 lp fold band and an 84 lp cutout could be
interesting. Cost: ~10 min.

**R4. Dark mode.**
Everything was measured at `platformBrightness: light`. `simctl ui <udid>
appearance dark` is a one-liner. Cost: ~5 min.

**R5. Safe-area reclaim, quantified in a real layout.**
Q3 computes ~44,000 lp² lost to the conservative inset. A side-by-side of
`SafeArea` versus a layout that uses the `occlusion` rectangle would show it
rather than assert it, the same way the hinge demo does. Cost: ~20 min.

**R6. The fold band across a real image or video surface.**
Currently the demo uses text and coloured panes. A photo cut by the hinge is
a stronger image if the article wants one. Cost: ~15 min.

---

## Medium — needs a few operator clicks

**R7. #193088 blackout duration, as a number.**
Currently the operator's qualitative observation: no flicker, but the screen
goes black for a few seconds. Instrumentable with `xcrun simctl io recordVideo`
across a fold and counting black frames. Cost: ~10 min plus 2 posture clicks.

**R8. Split View with `UIApplicationSupportsMultipleScenes = true`.**
Split View was verified to work with the stock `false`. Flipping it might
enable the small-pane state that does not currently exist, or change pane
sizing, or do nothing. Cost: ~15 min plus a few clicks.

**R9. The reproducible click path for rotating the inner screen.**
Inner portrait was measured (condition 03), but the operator found the
affordance by hand and the steps were not recorded. Five minutes of narrating
it while repeating would close the one remaining `NO VERIFICADO` that is
actually closeable.

**R10. Keyboard behaviour across every posture transition.**
Q10 established that going fully-open → half-open dismisses the keyboard
(#193096). The other transitions — half-open → closed, closed → open, and the
reverse of each — were not tested individually. Cost: ~15 min plus 6 clicks.

**R11. Overlays open across a posture change.**
What happens to an `AlertDialog` or a bottom sheet when the device folds? Not
tested. Cost: ~15 min plus a few clicks.

---

## Not possible from here

**R12. The inner panel's true native resolution.** Measured framebuffer is
2007 × 2853 px against a published 1878 × 2670. Needs hardware or an Apple
spec, not a simulator.

**R13. Anything about shipping hardware.** This is all iOS 27.1 beta on Xcode
27.1 beta, measured 2026-09-21, a month before the 2026-10-23 release. Real
hinge angles from a real sensor, real fold animation timing, real thermal or
battery behaviour — none of it is observable here.

**R14. Whether the `foldable` package works on a physical iPhone Duo.** It
works in the simulator, which is already more than `MediaQuery` manages. The
package's own docs flag `angleUnitVerified` as the field to watch; it read
`true` here.

---

## How to run anything from this list

```bash
# bring the device back
export DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer
xcrun simctl boot AA16FBB4-F351-4AD9-BBF5-45562B10CFDD
open "/Applications/Xcode-27.1-beta.app/Contents/Applications/DeviceHub.app"

cd duo-lab/duo_probe
mise exec -- flutter run -d AA16FBB4-F351-4AD9-BBF5-45562B10CFDD \
  | stdbuf -oL grep -vE "ToolKitConversion|Failed to index|Skipping:" \
  | tee -a ../findings/run.log
```

Then, from `duo-lab/`:

```bash
./lab.sh do tab/0            # 0 metrics, 1 overlays, 2 layout, 3 state, 4 hinge demo
./lab.sh do dialog           # also: datepicker, sheet, keyboard, dismiss
./lab.sh do orient/portrait  # also: landscape, free  (ignored on the inner screen)
./lab.sh do condition/<label>
./lab.sh do measure          # logs every overlay Material surface
./lab.sh do foldable         # logs the full foldable snapshot + native API dump
./lab.sh capture NN-name     # screenshots both displays + dumps metrics JSON
```

Posture is the one thing with no CLI: the three buttons at the bottom right of
the DeviceHub window, in order — closed, half open, fully open.
