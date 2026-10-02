# setPreferredOrientations re-test

Run 2026-09-28 to replace an earlier claim that was not supported by the logs.
Raw log: `orientation-retest.log` (written with `tee`, not overwritten).

## Why this was re-run

The first pass claimed two things the evidence did not support:

1. "No error, no exception, no signal of any kind." **False.** iOS emits
   `Failed to change device orientation: Error Domain=UISceneErrorDomain Code=101
   "The current windowing mode does not allow for programmatic changes to
   interface orientation."` It appears 10 times in the original logs.
2. "The same call works normally on the outer display." **Unsupported at the
   time.** All 12 logged `setPreferredOrientations` calls in the original logs
   were made at 951×669 or 669×951, i.e. on the inner display only. The outer
   rotation had happened, but its log was lost when `run.log` was overwritten
   before the harness switched to `tee -a`.

## Method

Single session, app running throughout, log appended and never truncated.
Device booted closed (outer display), tested, then switched to fully open
(inner display) and tested again. Each call's effect read from the probe's own
`MediaQuery.sizeOf` snapshot; errors counted from the simulator's stderr.

## Result

| Display | Request | Orientation after | `Code=101` emitted |
|---|---|---|---|
| Outer, closed | `[landscapeLeft, landscapeRight]` | 466×678 → **678×466** | no |
| Outer, closed | `[portraitUp]` | 678×466 → **466×678** | **yes** |
| Inner, fully open | `[portraitUp]` | 951×669 → **951×669** (no change) | yes |
| Inner, fully open | `[landscapeLeft, landscapeRight]` | 951×669 → 951×669 (already landscape) | yes |

## What this supports

- On the **inner display**, `setPreferredOrientations` does not change the
  orientation, and the windowing-mode `UISceneErrorDomain Code=101` appears
  around every inner-display request. The log does not let calls and errors be
  paired one to one, so read this as co-occurrence rather than causation.
- On the **outer display**, the orientation does change.
- The two displays produced **different** `Code=101` messages. Inner:
  "The current windowing mode does not allow for programmatic changes to
  interface orientation." Outer: "None of the requested orientations are
  supported by the view controller. Requested: portrait; Supported:
  landscapeLeft, landscapeRight" — which is iOS reporting back the
  landscape-only lock **our own previous command** had just set. The outer
  error is an artefact of the test sequence, not a device behaviour, and the
  request rotated anyway.
- The windowing-mode message also appears on a **posture change**, with no
  `setPreferredOrientations` call preceding it (`orientation-retest.log:104`).
- iOS attributes the refusal to the **current windowing mode**, not to the
  display. That is a different mechanism from "the inner screen ignores the
  API", and it is checkable by someone with more time than we had.

## What this does NOT support

- That the inner display is the cause. The error message names the windowing
  mode, and we did not vary the windowing mode independently of the display. We did not test the inner display in a different windowing mode, and we
  did not test the outer display in Split View.
- Any claim that the call fails silently. It does not.

## Earlier, separate observation (unchanged)

Three other rotation paths had no effect on the inner display: the simulator's
Orientation menu, its Rotate Left / Rotate Right commands, and
`xcrun simctl io <udid> screenConfig geometry`, which reports success and
changes nothing. The inner display does reach portrait through the simulator
UI; condition 03 was measured there at 669×951.
