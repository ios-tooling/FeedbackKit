# FeedbackKit — Design Spec

In-app feedback tool (SwiftUI SPM framework) for **internal beta / dogfooding**.
Trigger → capture screen → annotate → send to pluggable destinations for later review.

## Scope

- **Audience:** internal testers / dogfooding. Not shipped to production end users — no
  consent dialogs or PII-compliance burden (an opt-in blur tool still exists for convenience).
- **Platforms:** iOS-first (iPhone + iPad). macOS **deferred** — `trigger()` is a no-op that
  logs via Chronicle; package still compiles. **watchOS dropped** from the manifest.
- **Deployment targets:** iOS 17, macOS 14 — forced upward from the original iOS 16 by the
  Chronicle (iOS 17) and Convey/Chronicle (macOS 14) dependencies.

## Triggers

`FeedbackTriggers` OptionSet — `.shake`, `.floatingButton`, `.multiFingerGesture`
(2/3-finger long-press), `.programmatic`. Host selects any combination via the root modifier.
Default: `[.shake, .programmatic]`.

- Triggers are **suppressed while the editor is open** (no recursive capture).
- FeedbackKit's own chrome (e.g. floating button) is hidden before capture.

## Capture

- **Capture-before-present:** grab pixels synchronously at trigger, *then* present the editor
  over the frozen image.
- **Method:** `UIView.drawHierarchy(in:afterScreenUpdates:)` over the active `UIWindowScene`'s
  windows, composited (catches sheets, alerts, keyboard). Fidelity prioritized over theatrics.
  UIKit is acceptable here — the "SwiftUI-only" rule is a *layout* guideline.
- **Theatrics:** white flash, **no** shutter sound, **no** corner-thumbnail animation.

## Editor

- Layout: annotated image + **collapsible** comment field + **category picker**
  (Bug / Idea / Other). No severity in v1.
- Markup: **hybrid** — PencilKit (`PKCanvasView`) for freehand / highlighter / eraser + native
  feel + undo/redo; custom overlay for structured tools: **arrow, box/rectangle, text label,
  blur-redact region** (real pixelation on flatten). Color picker + overlay-undo.
  **Deferred (not yet built):** magnifier loupe, crop, emoji stamps.
- Presented as a `fullScreenCover` from the root modifier.
- **Immutable after send** — no edit-after-send; the outbox only retries delivery.

## Data model

`FeedbackReport` (Codable):

- **Flattened annotated image** (base + strokes + overlays) **+ original unannotated capture**,
  both **JPEG ~0.85**.
- Comment, category.
- **Auto-collected (always):** app version+build, iOS version, device model, locale/timezone,
  screen size + orientation, timestamp, free disk/memory, network reachability (Convey).
- **Host-provided (resolved at capture time):** `userID` (closure, re-read each capture),
  current screen name, arbitrary `[String: String]` metadata bag (from `.feedbackContext`).
- **Chronicle** breadcrumb/error trail ("what the user did right before").

## Transport

- **Pluggable** `FeedbackTransport` protocol (`func send(_:) async throws`) + a **`MultiTransport`**
  fan-out to N destinations.
- v1 conformers:
  - **CloudKit** — *default* / canonical image store. Serverless, fits the iCloud stack;
    "review later" via the CloudKit dashboard (companion viewer possible later).
  - **Slack** — **inline image upload required**, via bot token + channel ID, using the current
    two-step `files.getUploadURLExternal` → `files.completeUploadExternal` flow (`files:write`
    scope). Optional text-only incoming-webhook variant kept around.
  - **HTTP** (`HTTPTransport`) — generic JSON POST to a host-controlled URL (escape hatch).
    Built on `URLSession`, **not** Convey: Convey's shipped API only exposes a single shared
    `ConveyServer.default`, which a transport can't borrow without clobbering the host app's
    networking config (and an unconfigured server fails silently). Slack uses `URLSession` too.
- **Persistent on-disk outbox:** on Send, serialize report to disk, dismiss editor instantly, a
  background sender drains with retry/backoff across launches. **Achtung** toasts for
  success/failure + a "N pending" state.

## Public API (4 parts — `@Observable` / SwiftUI-native, no `ObservableObject`)

```swift
// 1. One-time, global config at launch (transports + credentials)
FeedbackKit.configure(
    transports: [
        CloudKitTransport(container: "iCloud.com.me.app"),
        SlackTransport(botToken: "xoxb-…", channel: "C0123"),
    ],
    userID: { currentUser?.id }            // closure, re-read at capture time
)

// 2. Root modifier — installs triggers + owns presentation
.feedbackKit(triggers: [.shake, .programmatic])

// 3. Per-screen context — pushed into the environment, read at capture time
.feedbackContext("CartScreen", metadata: ["cartID": cart.id])

// 4. Programmatic trigger (e.g. a debug-menu row)
FeedbackKit.trigger()
```

Global config holds app-wide transports/credentials; contextual info (screen name, metadata,
userID) is resolved at capture time so it is always current.

## Dependencies

Suite, CrossPlatformKit + **Chronicle**, **Achtung**. CloudKit, PencilKit (system).
Convey was dropped — transports use `URLSession` directly (see Transport section).

## Testing

**Swift Testing.** Cover the transport protocol, outbox persistence/drain, report serialization,
and metadata collection. Capture/markup UI = manual verification.
