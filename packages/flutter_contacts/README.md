# Patched flutter_contacts 2.1.0

Upstream: https://github.com/QuisApp/flutter_contacts (2.1.0)

## Why this fork exists

With `use_frameworks! :linkage => :static`, Xcode fails:

```text
'FlutterContactsPlugin' has different definitions in different modules;
first difference is definition in module 'flutter_contacts.Swift'
```

Upstream 2.x registers a pure-Swift `FlutterContactsPlugin`. Under static
frameworks, that symbol appears both in the umbrella module and in
`flutter_contacts.Swift`, which breaks `GeneratedPluginRegistrant.m`.

## Patch

1. Rename the Swift class to `SwiftFlutterContactsPlugin`.
2. Add an Objective-C shim (`ios/Classes/FlutterContactsPlugin.h/.m`) that
   forwards `registerWithRegistrar:` to Swift — same pattern as
   connectivity_plus after its pure-Swift regression.

Revisit when Flutter drops static frameworks / CocoaPods, or when upstream
ships an equivalent shim.
