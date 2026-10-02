# duo-lab

What a Flutter app actually does on the iPhone Duo, measured rather than
guessed.

We built a probe app that logs everything Flutter reports about the screen it
is drawing on, and drove it through twenty-one situations on the iPhone Duo
simulator: both displays, all three postures, rotated, in Split View, with the
keyboard up. Every condition has a screenshot of both displays and a full
metrics dump.

The write-up is **[findings/iphone-duo-flutter.md](findings/iphone-duo-flutter.md)**.

## What we found

- Your app runs. No migration, no SDK change, nothing crashes.
- `MediaQuery.displayFeatures` is **empty on iOS**, in all twenty-one
  conditions. Flutter cannot see the fold. Half open and fully open are
  indistinguishable to your code.
- Folding is not destructive. No rebuild, no `initState`, no state lost.
- The safe-area inset is **asymmetric**, 84 logical pixels on one edge, and
  which edge depends on posture.
- Split View on the inner display gives your app **469 logical pixels**, below
  almost every tablet breakpoint.
- `setPreferredOrientations` did not change orientation on the inner display in
  the state we measured, with `UISceneErrorDomain Code=101` co-occurring.

| Situation | Size (logical px) | Safe-area padding |
|---|---|---|
| Closed, portrait | 466 × 678 | right 84, bottom 34 |
| Closed, landscape | 678 × 466 | left 84, bottom 34 |
| Open, portrait | 669 × 951 | top 82, bottom 34 |
| Open, landscape | 951 × 669 | right 84, bottom 34 |
| Half open | 951 × 669 | right 84, bottom 34 |
| Open, beside another app | 469 × 669 | bottom 34 only |

## Layout

| Path | What |
|---|---|
| `findings/iphone-duo-flutter.md` | The article |
| `findings/REPORT.md` | Full report, ten questions, condition matrix |
| `findings/REQUESTS.md` | R1–R14, what can still be measured and what it costs |
| `findings/ENVIRONMENT.md` | Machine state and every install step |
| `findings/orientation-retest.md` | The re-test that corrected the first pass |
| `findings/*.json`, `*.png` | 21 conditions, both displays each |
| `findings/run.log` | Raw instrumentation |
| `duo_probe/` | The probe app, Flutter pinned to 3.47.5 |
| `lab.sh` | The harness |
| `render.py` | Renders the article to self-contained HTML |

## Reproducing it

Needs the **iOS 27.1 simulator runtime**; creating the device against 27.0
fails. That runtime currently ships with Xcode 27.1 beta and cannot be
downloaded from the command line, so it has to come through the Xcode
interface.

```bash
export DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer
xcrun simctl boot <your-duo-udid>
open "$DEVELOPER_DIR/../Applications/DeviceHub.app"

cd duo_probe
mise exec -- flutter run -d <your-duo-udid> | tee -a ../findings/run.log
```

Then drive it from the repo root:

```bash
./lab.sh do tab/0          # 0 metrics, 1 overlays, 2 layout, 3 state, 4 hinge demo
./lab.sh do dialog         # also: datepicker, sheet, keyboard, dismiss
./lab.sh do foldable       # foldable snapshot + native API dump
./lab.sh capture NN-name   # screenshots both displays + dumps metrics JSON
```

**Posture has no CLI.** It is three buttons at the bottom right of the
DeviceHub window, in order closed / half open / fully open, clicked by a
person. This is why foldable behaviour cannot be a regression test.

## Caveats

Measured 2026-09-21 and 2026-09-28 on one machine, on Xcode 27.1 beta, the iOS
27.1 simulator runtime and Flutter 3.47.5 stable — a month before the hardware
ships. Values that repeated across dozens of captures are reliable; the
portrait date picker was measured once, and the orientation finding rests on a
single pair of requests per display. `STATUS.md` lists the residual risks in
full. Numbers from a real device may differ, and we will re-run the matrix
after launch.

---

Built at [Somnio Software](https://somniosoftware.com).
