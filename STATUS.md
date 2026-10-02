# duo-lab — status

Paused 2026-09-21. Nothing running: simulators shut down, no `flutter run`,
DeviceHub closed.

## Where this stands

The lab is **deliverable**. `findings/REPORT.md` answers all ten questions of
the brief, the condition matrix is filled, and every number in it has been
audited (see below). `findings/REQUESTS.md` lists what can still be measured,
numbered R1–R14.

## Open items

**None that block the article.** R2 (#193035) was the one blocker and it was
closed 2026-09-28: all four navigation widgets — `TabBar` in an `AppBar`,
`TabBar` bare, Material 3 `NavigationBar`, and `BottomNavigationBar` — were
measured on both screens and every one fills its available width
(897.0/897.0 inner, 412.0/412.0 outer, eight measurements, zero failures).
Q6 and the bug table in `REPORT.md` now say **not reproduced**.

What remains in `REQUESTS.md` is optional enrichment: R7 (#193088 blackout
duration as a number) and R8 (Split View with
`UIApplicationSupportsMultipleScenes = true`), plus R1/R3–R6 and R10/R11.

## Audit already performed

Three passes, all clean:

1. **Every JSON against its screenshot.** 19 exact matches of
   `size × devicePixelRatio` against PNG pixel dimensions. The four
   non-matches are correct by construction (app on the other display, or
   Split View where the capture is the whole display).
2. **Every quoted number against raw log lines.** All six overlay
   measurements, all three `foldable` readings, and the keyboard inset
   264.0 → 0.26 appear verbatim in `run.log`.
3. **All derived arithmetic.** 20 of 20 correct — letterbox percentages,
   wasted-area figures, overlay shares, plus six consistency identities that
   could not hold if a measurement were wrong:
   - dialog content 739 + 24×2 padding = 787 (the independently measured width)
   - date picker panes 152 + 344 = 496 (the independently measured total)
   - occlusion width 951 − 867 = 84 = `padding.right`
   - occlusion height in portrait = 82 = `padding.top`
   - Split View 469 lp × 2 panes × 3 dpr + 39 px divider = 2853 px display width

## Known residual risk, for whoever writes the article

1. **#193035 and #193078** — both measured and not reproduced, but the safe
   phrasing is "did not reproduce in this configuration", not "the bug does
   not exist". #193035 was checked against all four navigation widgets;
   #193078 — measured and not reproduced, but the safe phrasing is "did not
   reproduce in this configuration", not "the bug does not exist".
3. **#193088** — the blackout is the operator's visual observation, not an
   instrumented duration. Do not invent a number. R7 would measure it.
4. **Single session, single machine.** Values that recurred across dozens of
   conditions are solid. Measured once: Split View, inner portrait, the
   portrait date picker.
5. **Beta software**, measured a month before the 2026-10-23 ship date. If the
   article publishes after release, re-run the matrix.
6. **Inner panel resolution** — measured 2007 × 2853 px against a published
   1878 × 2670. Marked `NO VERIFICADO`; the downsampling explanation fits but
   cannot be confirmed from a simulator.

## How to resume

```bash
export DEVELOPER_DIR=/Applications/Xcode-27.1-beta.app/Contents/Developer
xcrun simctl boot AA16FBB4-F351-4AD9-BBF5-45562B10CFDD
open "/Applications/Xcode-27.1-beta.app/Contents/Applications/DeviceHub.app"

cd duo_probe
mise exec -- flutter run -d AA16FBB4-F351-4AD9-BBF5-45562B10CFDD \
  | stdbuf -oL grep -vE "ToolKitConversion|Failed to index|Skipping:" \
  | tee -a ../findings/run.log
```

Then drive it from `duo-lab/` with `./lab.sh` — see the command list at the
bottom of `findings/REQUESTS.md`. Posture is the only thing with no CLI: three
buttons at the bottom right of the DeviceHub window, in order closed / half
open / fully open.

## Layout

| Path | What |
|---|---|
| `findings/REPORT.md` | The deliverable |
| `findings/REQUESTS.md` | R1–R14, what can still be measured and what it costs |
| `findings/ENVIRONMENT.md` | Machine state and every install step |
| `findings/*.json`, `*.png` | 21 conditions, both displays each |
| `findings/foldable-native-api-dump.txt` | Objective-C shape of `UIHinge` / `UIHingeInteraction` |
| `findings/run.log`, `run-part1.log` | Full instrumentation logs |
| `lab.sh` | The harness |
| `duo_probe/` | The probe app, Flutter pinned to 3.47.5 by `mise.toml` |
