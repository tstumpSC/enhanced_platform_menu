# enhanced_platform_menu

An enhanced drop-in replacement for Flutter’s **Platform Menu** API that adds
**checked menu items**, **icons**, and **better control over standard menus** —
working on **macOS and iPadOS**.

This package is fully compatible with Flutter's existing Platform Menu API, so it integrates
cleanly with `PlatformMenu`, `Actions`, and keyboard shortcuts.

---

## ✨ Features

- ✅ **Checked menu items**  
  Render checkmarks for toggleable commands

- 🖼 **Menu icons**  
  Attach SF Symbols or Flutter asset images to menu items and custom menus.

- 🧭 **Standard menu identifiers**  
  Explicitly target system menus like **File**, **Edit**, **View**, **Window**, and **Help**.

- 🧩 **Custom top-level menus**  
  Create your own menus with optional icons.

- 🗂 **Menu item grouping**  
  Group related items and automatically insert separators.

- ⌨️ **Keyboard shortcuts & Actions support**  
  Fully compatible with Flutter’s shortcut and `Actions` system.

- 🍎 **macOS + iPadOS support**  
  Uses native menu APIs on both platforms.

---

## Installation

```yaml
dependencies:
  enhanced_platform_menu: ^0.1.0
```

---

## Getting started
First, you need to set the platformMenuDelegate in your app to EnhancedPlatformMenuDelegate():
```dart
void main() {
  WidgetsBinding.instance.platformMenuDelegate = 
      EnhancedPlatformMenuDelegate();
  
  runApp(const MyApp());
}
```

Then you can define your menus like this:
```dart
final editMenu = EnhancedPlatformMenu.standard(
  identifier: StandardMenuIdentifier.edit,
  label: 'Edit',
  removeDefaultItems: true,
  menus: [
    EnhancedPlatformMenuItem(
      label: 'New',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyN,
        meta: true,
      ),
      onSelectedIntent: const NewIntent(),
    ),
    EnhancedPlatformMenuItemGroup(
      members: [
        EnhancedPlatformMenuItem(label: 'Open…'),
        EnhancedPlatformMenuItem(label: 'Close'),
      ],
    ),
  ],
);

```

Lastly, attach the menus to your app as usual with a PlatformMenuBar:
```dart
PlatformMenuBar(
  menus: [
    fileMenu,
    // other menus…
  ],
);
```

---

## Checked menu items
Use `checked` to render a native checkmark:
```dart
EnhancedPlatformMenuItem(
  label: 'Show Sidebar',
  checked: isSidebarVisible,
  shortcut: const SingleActivator(
    LogicalKeyboardKey.keyS,
    meta: true,
  ),
  onSelected: toggleSidebar,
);
```

---

## Menu icons
### SF Symbols
All 6.984 of Apple's SF Symbols are available to you via the SFSymbols class:
```dart
EnhancedPlatformMenuItem(
  label: 'Export',
  icon: SFSymbolIcon(
    SFSymbols.ac,
  ),
);
```

### Asset icons
You can also use your own assets:
```dart
EnhancedPlatformMenuItem(
  label: 'Print',
  icon: AssetIcon(
    'assets/icons/print.pdf',
  ),
);
```

Supported formats:
- PNG
- JPG
- PDF

---

## Standard top-level menus

Use the `.standard constructor to insert (or add additional items to) one of the system's default menus:
```dart
final editMenu = EnhancedPlatformMenu.standard(
  identifier: StandardMenuIdentifier.file,
  label: 'File',
  removeDefaultItems: true,
  menus: [
    // ...
  ],
);
```

Supported identifiers:
```dart
enum StandardMenuIdentifier {
  application,
  file,
  edit,
  format,
  view,
  services, // macOS only
  window,
  help,
}
```

Please note that your additional items might not appear in a standard menu if they use the exact same shortcut as an already existing one

### Removing default system items
Some of the standard menus will automatically add a few default items (like Undo/Redo in the Edit menu, see [Platform notes](#platform-notes) for details).
You can set `removeDefaultItems` to `true` in order to try to have them removed and hence get more control over the menu.
However, it is not guaranteed that this will work with every default menu item.

## Custom top-level menus
Use the `.custom constructor to insert a custom menu:

```dart
final customMenu = EnhancedPlatformMenu.custom(
  label: 'Custom',
  icon: SFSymbolIcon(
    SFSymbols.ac,
  ),
  menus: [
    EnhancedPlatformMenuItem(
      label: "Item with checked state, shortcut and icon",
      onSelectedIntent: const ToggleFlagIntent(),
      icon: SFSymbolIcon(SFSymbols.ac),
      shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, shift: true),
      checked: _flag.value,
    ),
  ],
);
```

You can also pass an icon to your custom menus for when they are not a top-level menu.

## Top-level order

Menus will always be automatically ordered according to the Apple Human Interface Guidelines:

Application | File | Edit | Format | View | Your custom menus | Window | Help

---

## How selection works
When a menu item is selected:
1. `onSelectedIntent` is resolved via Actions when possible
2. If no enabled Action exists, `onSelected` is invoked directly

This keeps behavior aligned with Flutter’s shortcut system.

---

## Platform notes
- on both platforms you should always provide a `.application`menu
- on macOS, you always have to provide a label in the `EnhancedPlatformMenu.standard` constructor. On iPadOS, this is not necessary  
- on ipadOS, the Window and Help menu will always be added automatically by the system. On macOS you can have a fully custom menu configuration
- on iPadOS, in the Edit menu you can only remove a few default items. Some, like `Emoji`, will always be there, even if you set `removeDefaultItems` to true. Others, like Undo, Redo, .. can be removed
- on iPadOS, the View menu contains a default "Show sidebar" item, which can be removed via the `removeDefaultItems` parameter
- on iPadOS, the Format menu contains 2 default items "Font" and "Text", which can be removed via the `removeDefaultItems` parameter
- on both platforms, the default items in the Window and Help menu can't be removed
