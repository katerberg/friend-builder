# AGENTS.md

## Cursor Cloud specific instructions

`friend_builder` (aka "Friend Crafter") is a **mobile-first Flutter app** (Android/iOS). Its
primary maintained run/deploy target is **iOS via Xcode Cloud → TestFlight** (see `README.md`),
which requires macOS/Xcode and cannot run in this Linux cloud VM.

### Toolchain (already installed in the VM image)
- Flutter SDK **3.35.7** (Dart 3.9.2) at `~/flutter`, on `PATH` via `~/.bashrc`. Pinned to match
  `pubspec.lock` (`sdks: dart >=3.9.0`, `flutter >=3.35.0`).
- Android SDK at `~/android-sdk` (`ANDROID_HOME`), on `PATH` via `~/.bashrc`.
- **JDK 17** at `/usr/lib/jvm/java-17-openjdk-amd64`. Flutter is configured to use it
  (`flutter config --jdk-dir`) because the repo's Gradle wrapper (`gradle-7.6.3`) does not support
  the VM's default Java 21.

### Working dev workflows (verified on this VM)
- Install deps: `flutter pub get` (this is the startup update script).
- Lint: `flutter analyze` — passes with no issues.
- Unit tests: `flutter test` — 50 tests pass (under `test/utils/`). These need no external services.
  A benign `MissingPluginException` from `AvatarSync` is logged during tests but they still pass.

### Running / building the app is NOT possible in this Linux VM
Do not burn time trying to launch the app here; all runnable paths are blocked by environment limits,
not by code bugs:
- **Android emulator (needs KVM): blocked by a host kernel bug.** The x86_64 emulator requires
  hardware acceleration. `KVM_CREATE_VCPU` triggers `kernel BUG at arch/x86/kvm/x86.c` /
  `kvm_spurious_fault` in `vmx_vcpu_create` (nested VMX). qemu starts but the guest never executes
  (0% CPU, device stays `offline`). Not fixable from inside the VM.
- **`flutter build apk` fails on the committed Gradle version.** Flutter 3.35's Gradle plugin uses
  the Gradle 8.3+ `filePermissions` API, but `android/gradle/wrapper/gradle-wrapper.properties` pins
  `gradle-7.6.3` (AGP 7.3.0). Build fails at `:gradle:compileKotlin` with
  `Unresolved reference: filePermissions`. Building Android would require bumping the Gradle wrapper
  and AGP (a code change), and would still need a device / KVM-capable host to run.
- **Web / Linux desktop are not viable.** `main()` awaits `sqflite` (`DebugData.removeDebug*`) and
  Firebase before `runApp`; neither is configured for web/Linux, so the app crashes at startup.
  Firebase is only configured for Android and iOS.

### Gotchas
- `flutter build`/`run` may auto-rewrite `android/app/build.gradle` (e.g. `minSdkVersion`). If that
  happens, revert with `git checkout -- android/app/build.gradle`.
- To actually run the app, use a real Android device / a host with working (nested) KVM after
  updating the Gradle wrapper, or build/run on macOS + Xcode (the maintained iOS path).
