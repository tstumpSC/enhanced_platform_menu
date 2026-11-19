## 0.4.0
- Shortcuts on special keys now show in the menu and trigger it: backspace, delete, escape, enter, the arrow keys, home/end, page up/down and F1–F20 (iPadOS: F1–F12; forward delete shows ⌦ via a hidden twin command). Previously only printable ASCII keys became key equivalents.
- **Behavior change:** the native menu now claims these keys before Flutter sees them — on macOS even while the item is disabled. An app that relied on, e.g., an `escape` menu shortcut falling through to a focused text field or dialog has to account for that. The same applies to the arrow keys (focus and text navigation); on iPadOS these commands take priority over system behavior. Tab is not supported: Flutter handles it before the native menu does, so a Tab shortcut would show but never fire.

## 0.3.1
- Relaxed Flutter constraint back to `>=3.3.0` (Dart SDK `^3.9.0`); the 0.3.0 bump to 3.41.0 was unnecessary — older Flutter ignores `Package.swift` and falls back to CocoaPods.
- Note: SPM build requires Flutter 3.44+. On older Flutter the plugin uses CocoaPods. If you are on Flutter 3.24–3.43 with SPM explicitly enabled, either upgrade to 3.44+ or disable SPM (`flutter config --no-enable-swift-package-manager`) for this plugin.

## 0.3.0
- Added Swift Package Manager support for iOS and macOS (CocoaPods still supported)
- **Breaking:** raised minimum Flutter to 3.41.0 (Dart SDK 3.11.0), required by Swift Package Manager

## 0.2.2
- Removed `dart:io` dependency so the package can be compiled for Web (no-op on Web — plugin still only functions on macOS/iPadOS)

## 0.2.1
- Fixed issue where items would always be enabled (macOS only)

## 0.2.0
- Added support for PlatformProvidedMenuItem
- Fixed issue where separator between default and custom items was missing

## 0.1.2
- Fixed typos in README

## 0.1.1
- Fixed formatting issues

## 0.1.0
- Initial release
- Adds EnhancedPlatformMenu which brings support for checked menu items and icons
- Supports macOS and iPadOS