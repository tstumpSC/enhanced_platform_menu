import 'package:enhanced_platform_menu/enhanced_platform_menu_icon.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu.dart';

/// Intents
class AboutIntent extends Intent {
  const AboutIntent();
}

class PreferencesIntent extends Intent {
  const PreferencesIntent();
}

class NewDocIntent extends Intent {
  const NewDocIntent();
}

class CloseWindowIntent extends Intent {
  const CloseWindowIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class ToggleFlagIntent extends Intent {
  const ToggleFlagIntent();
}

class SpecialKeyIntent extends Intent {
  const SpecialKeyIntent(this.name);

  final String name;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.platformMenuDelegate = EnhancedPlatformMenuDelegate();

  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final ValueNotifier<bool> _flag = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _lastAction = ValueNotifier<String?>(null);

  /// Shows [what] on screen and in the console, so every menu item and
  /// shortcut can be verified while testing.
  void _report(String what) {
    _lastAction.value = what;
    debugPrint(what);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: const Color(0xFF202020),
      // Actions that handle the Intents
      actions: <Type, Action<Intent>>{
        AboutIntent: CallbackAction<AboutIntent>(
          onInvoke: (i) {
            _report('About');
            return null;
          },
        ),
        PreferencesIntent: CallbackAction<PreferencesIntent>(
          onInvoke: (i) {
            _report('Preferences');
            return null;
          },
        ),
        NewDocIntent: CallbackAction<NewDocIntent>(
          onInvoke: (i) {
            _report('New document');
            return null;
          },
        ),
        CloseWindowIntent: CallbackAction<CloseWindowIntent>(
          onInvoke: (i) {
            _report('Close window');
            return null;
          },
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (i) {
            _report('Undo');
            return null;
          },
        ),
        RedoIntent: CallbackAction<RedoIntent>(
          onInvoke: (i) {
            _report('Redo');
            return null;
          },
        ),
        ToggleFlagIntent: CallbackAction<ToggleFlagIntent>(
          onInvoke: (i) {
            _flag.value = !_flag.value;
            _report('Toggle flag -> ${_flag.value ? 'ON' : 'OFF'}');
            return null;
          },
        ),
        SpecialKeyIntent: CallbackAction<SpecialKeyIntent>(
          onInvoke: (i) {
            _report(i.name);
            return null;
          },
        ),
      },
      builder: (context, child) {
        return ValueListenableBuilder(
          valueListenable: _flag,
          builder: (_, value, _) {
            return PlatformMenuBar(
              menus: [
                _customMenu,
                _specialKeysMenu,
                _platformProvidedMenuItems,
                ..._standardMenus,
              ],
              child: Center(
                child: ValueListenableBuilder<String?>(
                  valueListenable: _lastAction,
                  builder:
                      (_, key, _) => Text(
                        'Hello desktop/iPadOS!\nFlag is ${value ? 'ON' : 'OFF'}\n'
                        'Last action: ${key ?? '-'}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFE0E0E0)),
                      ),
                ),
              ),
            );
          },
        );
      },
      // minimal routing so WidgetsApp compiles
      onGenerateRoute:
          (settings) => PageRouteBuilder<void>(
            pageBuilder: (context, _, _) => const SizedBox.shrink(),
          ),
      locale: Locale("en"),
    );
  }

  PlatformMenu get _customMenu => PlatformMenu(
    label: 'Custom',
    menus: [
      PlatformMenuItemGroup(
        members: [
          EnhancedPlatformMenuItem(
            label: "Item with checked state, shortcut and icon",
            onSelectedIntent: const ToggleFlagIntent(),
            icon: SFSymbolIcon(SFSymbols.ac),
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyQ,
              shift: true,
            ),
            checked: _flag.value,
          ),
        ],
      ),
      PlatformMenuItemGroup(
        members: [
          PlatformMenu(
            label: "Nested menu regular",
            menus: [
              EnhancedPlatformMenuItem(label: "Nested menu item"),
              EnhancedPlatformMenuItem(label: "Nested menu item 2"),
            ],
          ),
          EnhancedPlatformMenu.custom(
            label: "Nested menu enhanced",
            icon: SFSymbolIcon(SFSymbols.sfs_1_magnifyingglass),
            menus: [
              EnhancedPlatformMenuItem(label: "Nested menu item"),
              EnhancedPlatformMenuItem(label: "Nested menu item 2"),
            ],
          ),
          PlatformMenuItem(
            label: 'Regular item',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyW,
              meta: true,
            ),
            onSelectedIntent: const CloseWindowIntent(),
          ),
        ],
      ),
    ],
  );

  /// One item per special key, bound to the bare key (no modifiers).
  /// Note: the native menu claims these keys before Flutter sees them.
  static const _specialKeys = <(String, LogicalKeyboardKey)>[
    ('Backspace', LogicalKeyboardKey.backspace),
    ('Forward delete', LogicalKeyboardKey.delete),
    ('Escape', LogicalKeyboardKey.escape),
    ('Enter', LogicalKeyboardKey.enter),
    ('Arrow up', LogicalKeyboardKey.arrowUp),
    ('Arrow down', LogicalKeyboardKey.arrowDown),
    ('Arrow left', LogicalKeyboardKey.arrowLeft),
    ('Arrow right', LogicalKeyboardKey.arrowRight),
    ('Home', LogicalKeyboardKey.home),
    ('End', LogicalKeyboardKey.end),
    ('Page up', LogicalKeyboardKey.pageUp),
    ('Page down', LogicalKeyboardKey.pageDown),
    ('F1', LogicalKeyboardKey.f1),
    ('F2', LogicalKeyboardKey.f2),
    ('F3', LogicalKeyboardKey.f3),
    ('F4', LogicalKeyboardKey.f4),
    ('F5', LogicalKeyboardKey.f5),
    ('F6', LogicalKeyboardKey.f6),
    ('F7', LogicalKeyboardKey.f7),
    ('F8', LogicalKeyboardKey.f8),
    ('F9', LogicalKeyboardKey.f9),
    ('F10', LogicalKeyboardKey.f10),
    ('F11', LogicalKeyboardKey.f11),
    ('F12', LogicalKeyboardKey.f12),
  ];

  PlatformMenu get _specialKeysMenu => PlatformMenu(
    label: 'Special keys',
    menus: [
      for (final (name, key) in _specialKeys)
        EnhancedPlatformMenuItem(
          label: name,
          shortcut: SingleActivator(key),
          onSelectedIntent: SpecialKeyIntent(name),
        ),
      // With a modifier: should also show and trigger.
      EnhancedPlatformMenuItem(
        label: 'Shift + Backspace',
        shortcut: const SingleActivator(
          LogicalKeyboardKey.backspace,
          shift: true,
        ),
        onSelectedIntent: const SpecialKeyIntent('Shift + Backspace'),
      ),
    ],
  );

  EnhancedPlatformMenu get _platformProvidedMenuItems =>
      EnhancedPlatformMenu.custom(
        label: "Platform provided menus",
        menus:
            PlatformProvidedMenuItemType.values
                .map(
                  (e) =>
                      PlatformProvidedMenuItem.hasMenu(e) &&
                              e != PlatformProvidedMenuItemType.servicesSubmenu
                          ? PlatformProvidedMenuItem(type: e)
                          : null,
                )
                .nonNulls
                .toList(),
      );

  List<EnhancedPlatformMenu> get _standardMenus => [
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.file,
      label: "File",
      menus: [
        PlatformMenuItem(
          label: 'New document',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
          onSelectedIntent: const NewDocIntent(),
        ),
      ],
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.edit,
      label: "Edit",
      removeDefaultItems: true,
      menus: [
        EnhancedPlatformMenuItem(
          label: 'Custom Undo',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
          onSelectedIntent: const UndoIntent(),
        ),
      ],
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.view,
      label: "View",
      menus: [],
      removeDefaultItems: true,
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.application,
      label: "Example app",
      menus: [
        PlatformMenuItemGroup(
          members: [
            PlatformMenuItem(
              label: 'About Example',
              onSelectedIntent: const AboutIntent(),
            ),
            PlatformMenuItem(
              label: 'Preferences…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.accel,
                meta: true,
              ),
              onSelectedIntent: const PreferencesIntent(),
            ),
          ],
        ),
        EnhancedPlatformMenu.standard(
          identifier: StandardMenuIdentifier.services,
          label: "Services",
          menus: [],
        ),
      ],
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.window,
      removeDefaultItems: true,
      label: "Window",
      menus: [
        PlatformMenuItem(
          label: "Additional window item",
          onSelectedIntent: PreferencesIntent(),
        ),
      ],
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.format,
      removeDefaultItems: false,
      label: "Format",
      menus: [
        PlatformMenuItem(
          label: "Additional window item",
          onSelectedIntent: PreferencesIntent(),
        ),
      ],
    ),
    EnhancedPlatformMenu.standard(
      identifier: StandardMenuIdentifier.help,
      removeDefaultItems: false,
      label: "Help",
      menus: [
        EnhancedPlatformMenuItem(
          label: "Additional help item",
          onSelectedIntent: PreferencesIntent(),
          icon: SFSymbolIcon(SFSymbols.a_circle),
        ),
      ],
    ),
  ];
}
