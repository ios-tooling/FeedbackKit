# AGENTS.md

Guidance for AI agents working in the FeedbackKit repo. Read this before making changes.

## What this is

A SwiftUI Swift Package providing in-app feedback for **internal beta/dogfooding**: trigger
→ capture screen → annotate → deliver to pluggable transports. Runs on **iOS and macOS**
(watchOS dropped). See `DESIGN.md` for full rationale.

## Build & test

```sh
swift build                                                          # macOS host
swift test                                                           # unit tests (macOS host)
xcodebuild build -scheme FeedbackKit -destination 'generic/platform=iOS'   # compile the iOS branch
```

**Run the iOS build before declaring done.** `swift build`/`swift test` exercise the macOS
branch (and the shared, now-cross-platform editor/flattener); the iOS-only freehand path
(PencilKit) and toolbar placements only compile under the `xcodebuild` step, so iOS-only
mistakes hide until then. Platform-specific code is fenced with `#if canImport(UIKit)` /
`#elseif canImport(AppKit)`.

## Architecture (by directory, under `Sources/FeedbackKit/`)

- `Model/` — `FeedbackReport` (self-contained Codable; JPEGs + optional `.m4a` audio as base64
  `Data`), category, auto-collected metadata, host context, breadcrumb summary. No UIKit (the
  metadata collector is `@MainActor` and guards UIKit bits).
- `Transport/` — `FeedbackTransport` protocol + `MultiTransport` fan-out + `HTTPTransport`,
  `CloudKitTransport`, `SlackTransport`, `LocalCollectionTransport` (writes directory bundles
  instead of sending). `HTTPSupport` holds shared URLSession helpers.
- `Collection/` — the local collect-and-export route: `FeedbackCollectionStore` (directory
  bundles + `NSFileCoordinator` zip, whole-collection or a single bundle), `CollectionItem`,
  `SharedReport` (a `Transferable` that zips one report on demand for a per-row `ShareLink`), and
  the public `FeedbackCollectionScreen` (+ `CollectionScreenModel`, `CollectionRow`) for
  review/delete/share — per-report Share on each row, whole-set Export in the toolbar.
- `Outbox/` — `OutboxStore` (one JSON file per report on disk), `OutboxSender` (headless drain),
  `FeedbackOutbox` (`@MainActor @Observable` manager: retry/backoff + Achtung toasts).
- `Capture/` — `ScreenCapturer` (iOS: composites all scene windows; macOS: key-window
  `extractImage`) + `CaptureFlashState`.
- `Triggers/` — `FeedbackKitModifier` (`.feedbackKit`), `FeedbackContextModifier`
  (`.feedbackContext`), `FeedbackWindowPresenter` (UIWindow / NSWindow), and the trigger
  affordances: shake/multi-finger gesture (iOS), keyboard shortcut (macOS), floating button.
- `Configuration/` — `FeedbackKit` (public facade), `FeedbackController`
  (`@MainActor @Observable` brain), configuration, `FeedbackDraft`, `FeedbackTriggers`.
- `Editor/` + `Editor/Markup/` — `FeedbackEditorScreen` + `FeedbackEditorToolbar`, the dictation-
  enabled `CommentField` (shown by default) + `FeedbackDictation` (drives TapeDeck's `Transcriber`
  + `AudioRecorder` off one mic button), the freehand
  canvas (PencilKit on iOS, `FreehandCanvasView`/`FreehandRenderer` on macOS), structured-
  annotation overlay/model, and the cross-platform `MarkupFlattener` (CGContext bitmap; takes the
  freehand layer pre-rendered as a `UXImage`, so it stays PencilKit-free).
- `Integrations/` — `ChronicleBreadcrumbs`.

Data flow: `FeedbackController.trigger()` → capture → `FeedbackDraft` → `FeedbackEditorScreen`
(comment + optional dictation/audio + markup) → `MarkupFlattener` → `FeedbackReport` →
`FeedbackOutbox` → `FeedbackTransport`. `LocalCollectionTransport` is just one such transport; the
export UI reads its bundles straight off disk via `FeedbackCollectionStore`.

## Conventions (from the owner's CLAUDE.md — follow exactly)

- **State:** `@Observable` only. Never `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`.
- **Concurrency:** async/await only — no Combine, GCD, or dispatch queues. (Notifications are
  consumed via `NotificationCenter.notifications(named:)` async sequences, not Combine.)
- **SwiftUI:** prefer new subview structs over view-returning computed properties. Full-screen
  views are named `*Screen`. Avoid hard-coded dimensions.
- **UIKit:** avoided except where unavoidable (screen capture, PencilKit hosting, shake/gesture
  recognizers). The "no UIKit fallback" rule is about *layout*, not these.
- **Files:** ~100 lines or less; split large types by functionality.
- **Tests:** Swift Testing (`import Testing`, `@Test`, `#expect`) — never XCTest.
- **Commits:** imperative mood; **do not mention any LLM/AI assistance** and do not add
  `Co-Authored-By` trailers. Never push or commit unless explicitly asked.
- Prefer the owner's frameworks (github.com/ios-tooling): Suite, CrossPlatformKit, Chronicle,
  Achtung, TapeDeck (audio capture + speech-to-text). (Convey was intentionally dropped — see below.)

## Decisions & gotchas

- **No Convey.** Transports use `URLSession` directly. Convey's shipped API only exposes a single
  shared `ConveyServer.default`; a transport can't get an isolated server (its `init` is
  internal), and borrowing the default would clobber the host app's networking and fail silently.
- **Deployment targets** are iOS 18 / macOS 15, raised from iOS 17 / macOS 14 by **TapeDeck**.
  The manifest is `swift-tools-version: 6.0` (required to name `.v18`/`.v15`) but pins
  `swiftLanguageModes: [.v5]` so existing code isn't dragged into a Swift 6 concurrency migration.
  Don't lower the targets without removing TapeDeck.
- **Voice dictation via TapeDeck.** `FeedbackDictation` starts `Transcriber` + `AudioRecorder`
  together off TapeDeck's shared `AudioSource`; finalized utterances append to the comment, the
  `.m4a` is attached as `report.audioData`. Needs host `Info.plist` keys `NSMicrophoneUsageDescription`
  + `NSSpeechRecognitionUsageDescription`; `TapeDeckPermissions` requests them. Can't be verified
  headlessly — needs a real host app + mic.
- **Local collection = a transport.** `LocalCollectionTransport` writes directory bundles; raw
  audio is materialized there only (remote transports carry the transcript in `comment`, not the
  `.m4a`). Export zips via `NSFileCoordinator` `.forUploading` — no zip dependency.
- **Capture before present.** Capture runs while FeedbackKit chrome is hidden
  (`controller.isCapturing`) and the flash is at opacity 0, so neither contaminates the image.
- **Annotation geometry is normalized** to `[0,1]` image coordinates so it survives any display
  size; `MarkupFlattener` re-scales to native resolution and pixelates blur regions via CoreImage.
- **Outbox is at-least-once.** Retry can re-deliver to transports that already succeeded; this is
  accepted for internal use.
- **Shake** (iOS) is detected by overriding `UIWindow.motionEnded` (posts a notification). It
  won't fire while a text field is first responder. macOS has no shake; use `.keyboardShortcut`
  (⌘⇧F), `.floatingButton`, or `.programmatic`.
- **Editor window.** The editor lives in its own top-level window (UIWindow at `.alert` level on
  iOS, a centered NSWindow on macOS) so it covers sheets the app already has up. On macOS, closing
  the window via its close button is treated as Cancel.
- **Tests are backend + flattener.** Capture/trigger/window UI still needs a real host app to
  verify; there are no headless UI tests. Don't claim UI works from `swift test` alone.

## Not yet implemented

- Markup extras: magnifier loupe, emoji stamps.
- CloudKit/Slack require live credentials (container ID / bot token) to verify end-to-end.
