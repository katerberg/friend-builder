# CarPlay communications — implementation plan

**Status:** Implemented on branch `cursor/carplay-communications-11d2` (builds on the WidgetKit + Siri PoC from #10).  
**Ship path:** iOS TestFlight (Xcode Cloud). Not buildable/testable on the Linux cloud VM.

---

## Product goal

Ship a **CarPlay communication app** that shows the **single most overdue/due contactable friend**, opens a Contact-style detail (name, photo, urgency, Call), dials **cellular `tel:` only**, and **logs a hangout** when dial succeeds (`CPTemplateApplicationScene.open` completion `true`).

**Non-goals:** multi-friend CarPlay lists, FaceTime/VoIP dialing, Android Auto, messaging as a CarPlay product surface (compliance only).

---

## Architecture (shipped)

| Topic | Decision |
| --- | --- |
| UI layer | Native CarPlay: `CPListTemplate` → `CPContactTemplate` → optional `CPActionSheetTemplate` → `tel:` |
| `flutter_carplay` | Not used (Contact template gap) |
| Ranking / hangouts / photos | Dart — `resolveTopDueFriend` + `dueFriendUrgencyLabel` + phone/photo enrichment in `CarPlayService` |
| Dial success | `scene.open` completion `true` → hangout |
| Hangout defaults | `when: now`, one contact, empty notes, not all-day |
| Empty root | Empty list message, no placeholder person |
| Multi-number | `CPActionSheetTemplate` |
| Compliance | Minimal SiriKit messaging (`INSendMessageIntent`, `INSearchForMessagesIntent`, `INSetMessageAttributeIntent`) via `MessagingIntents` extension |
| Entitlement | `com.apple.developer.carplay-communication` (Debug + Release) |

### MethodChannel (`friend_builder/carplay`)

**`getTopPerson` →** `{ found: false, reason? }` or `{ found: true, contactIdentifier, displayName, urgency, photoBase64?, phones: [{label, number}], hasPhone }`

**`logHangout` ←** `{ contactIdentifier }` → `{ ok: true }` / error

Dart → native `refresh` after friend/hangout writes (alongside WidgetKit snapshot refresh).

---

## Still required outside code

1. Request / receive the CarPlay communication entitlement from Apple; update provisioning / Xcode Cloud profiles.  
2. Verify on CarPlay Simulator and a real device.  
3. Do not App Review a CarPlay-enabled build until entitlement + messaging intents are approved and functional.

---

## Compliance notes

| Path | Fit | Plan |
| --- | --- | --- |
| Argue “Phone handoff via `tel:` only” | Matches Call UX | Expect Apple pushback; do not rely on alone |
| Add VoIP / CallKit | Conflicts with cellular `tel:` only | Rejected |
| **Minimal messaging surface** | Satisfies entitlement rules without changing Call UX | **Shipped as thin SMS handoff** |
