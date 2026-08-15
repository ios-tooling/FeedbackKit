# FeedbackKit

In-app feedback for iOS and macOS beta builds and dogfooding. Trigger it from anywhere in
your app, it captures the current screen like a native screenshot, the tester annotates and
comments, and the report is delivered to a destination you choose for review later.

> Built for **internal testing** — there are no consent dialogs or App Store-facing flows.

## Features

- **Faithful capture** — on iOS, composites every window in the active scene (app content,
  presented sheets, alerts, keyboard) into one image, then a white screenshot flash; on macOS,
  snapshots the app's key window (no Screen Recording permission). Captured *before* any
  FeedbackKit UI appears, so the editor never ends up in the shot.
- **Markup** — freehand drawing (PencilKit on iOS, a SwiftUI canvas on macOS) plus placeable
  **arrow, box, text, blur-redact** (real pixelation) overlays and **crop**, with a color picker.
- **Pluggable delivery** — ships with CloudKit, Slack (inline image upload), and a generic HTTP
  transport. Fan out to several at once. Add your own by conforming to `FeedbackTransport`.
- **Voice dictation** — a mic button in the comment field transcribes speech into the comment
  (via [TapeDeck](https://github.com/ios-tooling/TapeDeck), on-device) and records the audio
  alongside, attached to the report.
- **Collect & export** — add `LocalCollectionTransport` to keep feedback on-device: each report
  (text + audio + screenshot) is bundled into its own folder, ready to review and bulk-export as a
  single zip via email, AirDrop, or Files — for a build without a live backend.
- **Never loses a report** — a persistent on-disk outbox delivers with retry/backoff and
  survives app kills, so reports filed offline send when the network returns.
- **Rich context** — auto-attaches app/device/OS metadata and recent
  [Chronicle](https://github.com/ios-tooling/Chronicle) breadcrumbs ("what the user did right
  before"), plus host-supplied screen name and metadata.

## Requirements

- iOS 18+ and macOS 15+ (raised by TapeDeck, used for voice dictation).
- Swift 6 toolchain / Xcode 16+ (the package builds in Swift 5 language mode).
- For voice dictation, add these keys to your app's `Info.plist`:
  - `NSMicrophoneUsageDescription` — e.g. "Records a voice note with your feedback."
  - `NSSpeechRecognitionUsageDescription` — e.g. "Transcribes your spoken feedback into text."

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/your-org/FeedbackKit.git", from: "0.1.0")
```

## Quick start

```swift
import FeedbackKit
import Achtung

@main
struct MyApp: App {
    init() {
        Achtung.instance.setup()          // required once, enables success/failure toasts

        FeedbackKit.configure(
            transports: [
                CloudKitTransport(containerID: "iCloud.com.you.app"),
                SlackTransport(botToken: "xoxb-…", channelID: "C0123456"),
            ],
            userID: { CurrentUser.shared.id }   // re-read at each capture
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .feedbackKit(triggers: [.shake, .keyboardShortcut, .programmatic])   // apply once, near the root
        }
    }
}
```

Tag screens so reports know where they came from:

```swift
CartScreen()
    .feedbackContext("CartScreen", metadata: ["cartID": cart.id])
```

Trigger it yourself (e.g. a debug-menu row):

```swift
Button("Send Feedback") { FeedbackKit.trigger() }
```

## Triggers

Pass any combination to `.feedbackKit(triggers:)`:

| Trigger | Platform | Description |
| --- | --- | --- |
| `.shake` | iOS | Shake the device. |
| `.keyboardShortcut` | macOS | ⌘⇧F. |
| `.floatingButton` | iOS · macOS | A draggable bubble, hidden during capture. |
| `.multiFingerGesture` | iOS | Two-finger long-press. |
| `.screenshot` | iOS | Taking a system screenshot. |
| `.programmatic` | iOS · macOS | Call `FeedbackKit.trigger()`. |

Default is `[.shake, .keyboardShortcut, .programmatic]` — each is ignored on platforms that
don't support it. Triggers are suppressed while the editor is open.

`.screenshot` re-captures the scene itself rather than reading the screenshot iOS just saved,
so it needs no photo library permission and no `Info.plist` keys. iOS never hands the app the
screenshot image; reaching it through Photos would mean an authorization prompt, a race against
the asset appearing in the library, a hard failure under limited-access, and a system
confirmation alert on every attempt to delete it (the asset isn't one the app created). The
system's copy therefore stays in the user's library. The trade-off is the one already shared by
every other trigger: `drawHierarchy` renders Metal, SceneKit, and video layers black, where a
true system screenshot would not.

## Transports

| Transport | Setup | Review surface |
| --- | --- | --- |
| `CloudKitTransport(containerID:scope:recordType:)` | Add the CloudKit capability + container to your app's entitlements. A `FeedbackReport` record type is created on first save. | CloudKit dashboard |
| `SlackTransport(botToken:channelID:)` | Bot token with the `files:write` scope; bot must be in the channel. | Slack channel (image inline) |
| `HTTPTransport(endpoint:headers:)` | Any endpoint that accepts a JSON `POST`. | Your server |
| `LocalCollectionTransport(directory:)` | None — writes bundles on-device. | In-app collection screen / exported zip |
| `MultiTransport([…])` | Wraps several transports; fans out concurrently. | — |

Delivery is **at-least-once**: if any transport fails, the report stays queued and retries, which
can re-deliver to transports that already succeeded.

### Custom transport

```swift
struct MyTransport: FeedbackTransport {
    func send(_ report: FeedbackReport) async throws {
        // report.annotatedImageData, .originalImageData, .audioData, .comment,
        // .category, .metadata, .context, .userID, .breadcrumbs
    }
}
```

## Collect & export

For builds without a live backend, keep feedback on-device and export it in bulk later. Add
`LocalCollectionTransport` (on its own, or alongside remote transports to do both):

```swift
FeedbackKit.configure(transports: [LocalCollectionTransport()])   // collect-only
```

Each report becomes its own folder — `feedback.json` plus `screenshot.jpg` / `original.jpg` /
`audio.m4a` sidecars.

When feedback is triggered, the window is a **swipe pager**: the editor for the report you're
filing now, then swipe left (iOS) / the second tab (macOS) to the export screen — no host code
needed. The report you're currently writing appears there too, as a live **"Draft — unsent"** row
that updates as you type; it becomes a saved, shareable item once you tap Send. **Export All**
zips the whole collection to the share sheet — and folds in the current report too, as long as
you've added something to it (text, audio, or markup). You can also **Clear All** (wipe the
collection, with confirmation), delete a single item (swipe), or **Share** one report from its row.

You can also present the same export screen standalone, e.g. from a debug menu:

```swift
.sheet(isPresented: $showFeedback) {
    FeedbackKit.collectionScreen()
}
```

Or drive the export yourself:

```swift
if let zipURL = await FeedbackKit.exportCollection() {
    // hand zipURL to a ShareLink, mail composer, etc.
}
```

## How it works

Trigger → hide FeedbackKit chrome → capture the screen (scene windows on iOS, the key window
on macOS) → flash (iOS) → collect metadata + breadcrumbs → present the editor over the frozen
image in its own window → on **Send**, the markup is flattened into the screenshot at native
resolution, written to the outbox, and the editor dismisses immediately while the outbox
delivers in the background.

## Not yet implemented

- Markup extras: magnifier loupe, emoji stamps.
- Shake (iOS) is not detected while a text field is the first responder.

See [`DESIGN.md`](DESIGN.md) for the full design rationale.
