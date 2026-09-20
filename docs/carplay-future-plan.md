# CarPlay communications — future plan (deferred)

**Status:** Not implemented in the current WidgetKit + Siri PoC.  
**This round shipped instead:** home-screen WidgetKit (`DueFriendWidget`) + App Intent (`WhoShouldIHangOutWithIntent`) proving the “top overdue friend” ranking and copy.  
**Ship path for CarPlay later:** iOS TestFlight (Xcode Cloud). Not buildable/testable on the Linux cloud VM.

---

## Why this is deferred

Apple’s CarPlay **communication** category requires:

1. Entitlement `com.apple.developer.carplay-communication` (request via [Apple’s CarPlay form](https://developer.apple.com/contact/carplay))
2. Either short-form **messaging** (SiriKit message intents) **or** VoIP (CallKit + `INStartCallIntent`)

Friend Builder’s product Call UX is cellular `tel:` only (not VoIP). Messaging is not a product feature. Building an honest compliance surface + entitlement gate is a separate round from proving “who is due” on the phone.

The WidgetKit + Siri PoC validates ranking, urgency copy, and App Group snapshot plumbing that CarPlay can reuse later.

---

## Product goal (future)

Ship a **CarPlay communication app** that shows the **single most overdue/due contactable friend**, opens a Contact-style detail (name, photo, urgency, Call), dials **cellular `tel:` only**, and **logs a hangout** when dial succeeds (`CPTemplateApplicationScene.open` completion `true`).

**Non-goals for that future round (same as research):** multi-friend CarPlay lists, FaceTime/VoIP dialing, Android Auto, messaging as a CarPlay product surface (compliance only).

---

## Locked architecture (future)

| Topic | Decision |
| --- | --- |
| UI layer | Native CarPlay: `CPListTemplate` → `CPContactTemplate` → optional `CPActionSheetTemplate` → `tel:` |
| `flutter_carplay` | Not primary for Contact UX (package gap) |
| Ranking / hangouts / photos | Dart — reuse [`resolveTopDueFriend`](../lib/services/top_due_friend.dart) / [`dueFriendUrgencyLabel`](../lib/utils/due_friend_urgency.dart) proven in the PoC |
| Dial success | `scene.open` completion `true` → hangout |
| Hangout defaults | `when: now`, one contact, empty notes, not all-day |
| Empty root | Empty list message, no placeholder person |
| Multi-number | `CPActionSheetTemplate` |
| Compliance | Minimal SiriKit messaging surface (`INSendMessageIntent`, `INSearchForMessagesIntent`, `INSetMessageAttributeIntent`); not VoIP |
| Entitlement | `com.apple.developer.carplay-communication` |

Urgency copy must match Friends [`ContactTile`](../lib/pages/friends/components/contact_tile.dart):

- No latest hangout → `"Never seen!"`
- `daysLeft > 0` → `"N days to go"`
- else → `"N days late"`

### MethodChannel contract (shared with Siri)

**`getTopPerson` →** `{ found: false, reason? }` or `{ found: true, contactIdentifier, displayName, urgency, … }`

Shipped for warm-path Siri (`WhoShouldIHangOutWithIntent`): recomputes ranking in Dart, publishes the App Group snapshot, and returns the live payload. Cold path / WidgetKit still read the last App Group snapshot.

**`logHangout` ←** `{ pendingId, contactIdentifier, displayName? }` → `{ ok: true }` / error

After a durable hangout commit (channel or pending-queue drain), Dart flushes [NativeProjectionService.refreshNow] so ranking/urgency are not left stale. UI/DB mutations notify [StorageChangeBus]; the projection service debounces and republishes snapshot + catalog without Storage importing widget/Siri code.

Channel name: `com.example.friend_builder/hangouts`.

Siri `LogHangoutIntent` is **queue-only**: it verifies an App Group enqueue (one UserDefaults key per `pendingId`, not a shared JSON array) and never calls MethodChannel `logHangout`. Dart drain is the sole SQLite writer for Siri hangouts. Drain lists pending keys via MethodChannel, claims each `pendingId` in SQLite (`processed_pending_hangouts`), creates the hangout, then deletes **only that id's key**. `openAppWhenRun` opens the app so drain happens soon; durability is the verified per-id queue write.

Hangout defaults: `when: now`, one contact, empty notes, not all-day.

Phone dial strings: digits + optional leading `+` for `tel:` URLs (helpers can live next to ranking when dial work starts).

---

## Compliance findings (keep in this doc until implemented)

| Path | Fit | Plan |
| --- | --- | --- |
| Argue “Phone handoff via `tel:` only” | Matches Call UX | Expect Apple pushback; do not rely on alone |
| Add VoIP / CallKit | Conflicts with cellular `tel:` only | Reject for product |
| **Minimal messaging surface** | Satisfies entitlement rules without changing Call UX | **Chosen when CarPlay ships** |

Do **not** submit a CarPlay-enabled App Review build until entitlement is granted and messaging intents are functional enough for communication-category review.

---

## Suggested future delivery sequence

1. Apple entitlement request + provisioning / Xcode Cloud profiles  
2. Minimal SiriKit messaging intents extension (compliance; SMS handoff OK)  
3. Native CarPlay scene shell (list / empty / loading) + MethodChannel to Dart ranking  
4. `CPContactTemplate`, Call, multi-number sheet, `tel:` open + hangout  
5. Refresh after hangout / foreground  
6. CarPlay Simulator + device + TestFlight verification  

---

## Reuse from this PoC

Already in tree for CarPlay to pick up later:

- Ranking: `resolveTopDueFriend` (same sort as Friends)
- Urgency: `dueFriendUrgencyLabel`
- Snapshot keys / App Group pattern (`group.com.example.friendBuilder`) — WidgetKit + cold Siri fallback; warm Siri uses live `getTopPerson`
- Siri hangout logging: queue-only `LogHangoutIntent` + claim/idempotent `HangoutIntentService` drain (`processed_pending_hangouts`) + `NativeProjectionService` refresh
- App Shortcuts discoverability: `FriendBuilderAppShortcuts.updateAppShortcutParameters()` after friend-catalog publish (and on launch); capped `suggestedEntities` (80); one-time iOS tip + Settings → Siri & Shortcuts
- Warm-path `getTopPerson` MethodChannel (extend later with phones / photoBase64 for CarPlay); `logHangout` MethodChannel remains for CarPlay dial-success, not Siri
- Domain → projection seam: `StorageChangeBus` + debounced `NativeProjectionService` (Storage no longer imports widget/Siri code)

**Device QA (Siri / Shortcuts — not runnable in Linux CI):** After install, confirm Shortcuts → Friend Builder lists “Who's due” and “Log hangout”, turn **Siri** on, speak near-paraphrases of registered phrases on iOS 17+, and verify parameterized friend names resolve after a catalog refresh.

---

## App Group note (current PoC)

WidgetKit + App Intent use App Group `group.com.example.friendBuilder`. That requires a paid Apple Developer account and enabling the group on Runner + `DueFriendWidgetExtension` in the developer portal / Xcode before device builds work.
