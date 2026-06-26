# AGENTS.md

Guidance for AI agents working in the FeedbackKit repo. Read this before making changes.

## What this is

A SwiftUI Swift Package providing in-app feedback for **internal iOS beta/dogfooding**: trigger
→ capture screen → annotate → deliver to pluggable transports. iOS-first; macOS compiles but is
deferred (capture/editor are no-ops). See `DESIGN.md` for full rationale.

## Build & test

```sh
swift build                                                          # macOS host
swift test                                                           # unit tests (macOS host)
xcodebuild build -scheme FeedbackKit -destination 'generic/platform=iOS'   # compile the iOS branch
```

**Always run the iOS build before declaring done.** Most of the code is inside
`#if canImport(UIKit) && !os(watchOS)`; the macOS `swift build`/`swift test` does *not* compile
it, so iOS-only mistakes hide until the `xcodebuild` step.

## Architecture (by directory, under `Sources/FeedbackKit/`)

- `Model/` — `FeedbackReport` (self-contained Codable; JPEGs as base64 `Data`), category,
  auto-collected metadata, host context, breadcrumb summary. No UIKit (the metadata collector is
  `@MainActor` and guards UIKit bits).
- `Transport/` — `FeedbackTransport` protocol + `MultiTransport` fan-out + `HTTPTransport`,
  `CloudKitTransport`, `SlackTransport`. `HTTPSupport` holds shared URLSession helpers.
- `Outbox/` — `OutboxStore` (one JSON file per report on disk), `OutboxSender` (headless drain),
  `FeedbackOutbox` (`@MainActor @Observable` manager: retry/backoff + Achtung toasts).
- `Capture/` — `ScreenCapturer` (composites all scene windows) + `CaptureFlashState`.
- `Triggers/` — `FeedbackKitModifier` (`.feedbackKit`), `FeedbackContextModifier`
  (`.feedbackContext`), shake/gesture/floating-button triggers.
- `Configuration/` — `FeedbackKit` (public facade), `FeedbackController`
  (`@MainActor @Observable` brain), configuration, `FeedbackDraft`, `FeedbackTriggers`.
- `Editor/` + `Editor/Markup/` — `FeedbackEditorScreen`, PencilKit canvas, structured-annotation
  overlay/model/flattener, toolbar.
- `Integrations/` — `ChronicleBreadcrumbs`.

Data flow: `FeedbackController.trigger()` → capture → `FeedbackDraft` → `FeedbackEditorScreen`
→ `MarkupFlattener` → `FeedbackReport` → `FeedbackOutbox` → `FeedbackTransport`.

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
  Achtung. (Convey was intentionally dropped — see below.)

## Decisions & gotchas

- **No Convey.** Transports use `URLSession` directly. Convey's shipped API only exposes a single
  shared `ConveyServer.default`; a transport can't get an isolated server (its `init` is
  internal), and borrowing the default would clobber the host app's networking and fail silently.
- **Deployment targets** are iOS 17 / macOS 14, forced up from iOS 16 by Chronicle (iOS 17) and
  Convey/Chronicle (macOS 14). Don't lower them without removing those deps.
- **Capture before present.** Capture runs while FeedbackKit chrome is hidden
  (`controller.isCapturing`) and the flash is at opacity 0, so neither contaminates the image.
- **Annotation geometry is normalized** to `[0,1]` image coordinates so it survives any display
  size; `MarkupFlattener` re-scales to native resolution and pixelates blur regions via CoreImage.
- **Outbox is at-least-once.** Retry can re-deliver to transports that already succeeded; this is
  accepted for internal use.
- **Shake** is detected by overriding `UIWindow.motionEnded` (posts a notification). It won't fire
  while a text field is first responder.
- **Tests are backend-only.** The capture/markup/trigger UI needs a real iOS host app to verify;
  there are no headless UI tests. Don't claim UI works from `swift test` alone.

## Not yet implemented

- Markup extras: magnifier loupe, crop, emoji stamps.
- CloudKit/Slack require live credentials (container ID / bot token) to verify end-to-end.
