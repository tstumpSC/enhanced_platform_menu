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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: const Color(0xFF202020),
      // Actions that handle the Intents
      actions: <Type, Action<Intent>>{
        AboutIntent: CallbackAction<AboutIntent>(
          onInvoke: (i) {
            debugPrint('About…');
            return null;
          },
        ),
        PreferencesIntent: CallbackAction<PreferencesIntent>(
          onInvoke: (i) {
            debugPrint('Open Preferences');
            return null;
          },
        ),
        NewDocIntent: CallbackAction<NewDocIntent>(
          onInvoke: (i) {
            debugPrint('New document');
            return null;
          },
        ),
        CloseWindowIntent: CallbackAction<CloseWindowIntent>(
          onInvoke: (i) {
            debugPrint('Close window');
            return null;
          },
        ),
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (i) {
            debugPrint('Undo');
            return null;
          },
        ),
        RedoIntent: CallbackAction<RedoIntent>(
          onInvoke: (i) {
            debugPrint('Redo');
            return null;
          },
        ),
        ToggleFlagIntent: CallbackAction<ToggleFlagIntent>(
          onInvoke: (i) {
            _flag.value = !_flag.value;
            debugPrint('Toggled flag -> ${_flag.value}');
            return null;
          },
        ),
      },
      builder: (context, child) {
        return ValueListenableBuilder(
          valueListenable: _flag,
          builder: (_, value, _) {
            return PlatformMenuBar(
              menus: [_customMenu, ..._standardMenus],
              child: Center(
                child: Text(
                  'Hello desktop/iPadOS!\nFlag is ${value ? 'ON' : 'OFF'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFE0E0E0)),
                ),
              ),
            );
          },
        );
      },
      // minimal routing so WidgetsApp compiles
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
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
