# FeedbackKit — Design Spec

In-app feedback tool (SwiftUI SPM framework) for **internal beta / dogfooding**.
Trigger → capture screen → annotate → send to pluggable destinations for later review.

## Scope

- **Audience:** internal testers / dogfooding. Not shipped to production end users — no
  consent dialogs or PII-compliance burden (an opt-in blur tool still exists for convenience).
- **Platforms:** iOS (iPhone + iPad) **and macOS**. **watchOS dropped** from the manifest.
- **Deployment targets:** iOS 18, macOS 15 — raised from iOS 17 / macOS 14 by the **TapeDeck**
  dependency (voice dictation + recording). The manifest is `swift-tools-version: 6.0` (needed to
  name `.v18`/`.v15`) but pins the **Swift 5 language mode** to avoid an unrelated concurrency migration.

## Triggers

`FeedbackTriggers` OptionSet — `.shake` (iOS), `.floatingButton`, `.multiFingerGesture`
(2/3-finger long-press, iOS), `.keyboardShortcut` (⌘⇧F, macOS), `.programmatic`. Host selects
any combination via the root modifier; triggers unavailable on a platform are ignored.
Default: `[.shake, .keyboardShortcut, .programmatic]`.

- Triggers are **suppressed while the editor is open** (no recursive capture).
- FeedbackKit's own chrome (e.g. floating button) is hidden before capture.

## Capture

- **Capture-before-present:** grab pixels synchronously at trigger, *then* present the editor
  over the frozen image.
- **Method (iOS):** `UIView.drawHierarchy(in:afterScreenUpdates:)` over the active
  `UIWindowScene`'s windows, composited (catches sheets, alerts, keyboard). Fidelity prioritized
  over theatrics. UIKit is acceptable here — the "SwiftUI-only" rule is a *layout* guideline.
- **Method (macOS):** snapshot the app's key window content view via
  `NSView.cacheDisplay` (CrossPlatformKit's `extractImage`). App-scoped, so **no Screen
  Recording (TCC) permission** — mirrors the iOS scope of "just this app".
- **Theatrics:** white flash on iOS, **no** shutter sound, **no** corner-thumbnail animation.
  macOS skips the flash.

## Editor

- Layout: annotated image + comment field (**shown by default** on entry) + **category picker**
  (Bug / Idea / Other). No severity in v1.
- **Voice dictation:** a mic button in the comment field starts a live transcription session via
  **TapeDeck** (`Transcriber` — SpeechAnalyzer on OS 26+, SFSpeechRecognizer below). Finalized
  speech is appended to the comment; the raw audio is recorded to `.m4a` in parallel
  (`AudioRecorder`, off the same shared mic tap) and attached to the report. Permissions come from
  `TapeDeckPermissions` — the host app must supply the mic + speech-recognition usage strings.
- Markup: **hybrid** — freehand drawing (PencilKit `PKCanvasView` on iOS; a SwiftUI
  `Canvas` + drag drawer on macOS, since PencilKit is iOS-only) + a custom overlay for
  structured tools: **arrow, box/rectangle, text label, blur-redact region** (real pixelation
  on flatten) + **crop**. Color picker + overlay-undo. The flattener is platform-agnostic: it
  composites an explicit `CGContext` bitmap and takes the freehand layer pre-rendered, so it
  never imports PencilKit. **Deferred:** magnifier loupe, emoji stamps.
- Presented as a `fullScreenCover`-style window: a dedicated `UIWindow` (iOS) / `NSWindow`
  (macOS) at the top of the stack, owned by the root modifier.
- **Immutable after send** — no edit-after-send; the outbox only retries delivery.

## Data model

`FeedbackReport` (Codable):

- **Flattened annotated image** (base + strokes + overlays) **+ original unannotated capture**,
  both **JPEG ~0.85**.
- **Dictated audio** (`audioData`, AAC/`.m4a`), `nil` when none was recorded. Materialized to disk
  only by the collection route; remote transports convey the spoken content via the transcript.
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
  - **Local collection** (`LocalCollectionTransport`) — the "collect and export later" route.
    Instead of sending, it writes each report as a **directory bundle** (`feedback.json` +
    `screenshot.jpg`/`original.jpg`/`audio.m4a` sidecars) into a persistent `FeedbackKitCollection`
    folder. Just another transport, so it **fans out alongside** the remote ones (or is used alone
    for a collect-only app). `FeedbackCollectionStore` manages the folders; `FeedbackKit.exportCollection()`
    zips the whole folder (via `NSFileCoordinator` `.forUploading`, no new dependency) and
    `FeedbackKit.collectionScreen()` is a ready-made list with delete + `ShareLink` export (email,
    AirDrop, Files, …).
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

Suite, CrossPlatformKit + **Chronicle**, **Achtung**, **TapeDeck** (voice dictation/recording).
CloudKit, PencilKit, Speech, AVFoundation (system). Convey was dropped — transports use
`URLSession` directly (see Transport section).

## Testing

**Swift Testing.** Cover the transport protocol, outbox persistence/drain, report serialization,
and metadata collection. Capture/markup UI = manual verification.
