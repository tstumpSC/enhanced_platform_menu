import 'package:enhanced_platform_menu/enhanced_platform_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// EnhancedPlatformMenuDelegate
/// ----------------------------
/// A `PlatformMenuDelegate` that bridges Flutter’s platform menu API to a
/// host-platform implementation over a `MethodChannel` (`"enhanced_platform_menu"`).
/// It serializes Flutter `PlatformMenuItem` trees (including enhanced variants)
/// into a channel-friendly payload, sends them to the host, and routes menu
/// selection callbacks back into Flutter.
///
/// What it does
/// - `setMenus` / `clearMenus`: Publishes or clears the entire top-level menu
///   structure via channel methods `Menu.Set` and `Menu.Clear`.
/// - Serialization: Converts `PlatformMenu`, `PlatformMenuItem`, and
///   `PlatformMenuItemGroup` into a nested map:
///   - Menus: `{ kind: 'menu', label, children, [identifier], [removeDefaults], [icon...] }`
///   - Leaf items: `{ kind: 'leaf', id, label, enabled, [shortcut], [checked], [icon...] }`
///   - Group separators are emitted between grouped items as `{ kind: 'separator' }`.
///   - Supports `EnhancedPlatformMenu` (identifier, removeDefaults, optional icon)
///     and `EnhancedPlatformMenuItem` (checked, optional icon).
/// - Shortcuts: Serializes `MenuSerializableShortcut` using
///   `serializeForMenu().toChannelRepresentation()`.
/// - Selection handling: Registers a per-item callback keyed by a generated `id`.
///   When the host sends `Menu.Selected` with that `id`, the delegate:
///     1) Tries to invoke the item’s `onSelectedIntent` via `Actions` (using the
///        current focus context or a debug-locked context), and if enabled,
///        calls it; otherwise
///     2) Falls back to calling `onSelected`.
///
/// Debug locking (assert-only)
/// - `debugLockDelegate(context)` and `debugUnlockDelegate(context)` enforce that
///   only one `BuildContext` (the locker) may be used to resolve `Actions` when
///   no focused context is available. In release builds these always return `true`.
///
/// Channel contract
/// - Outbound:
///   - `Menu.Set` with `{ menus: [...] }`
///   - `Menu.Clear`
/// - Inbound:
///   - `Menu.Selected` with `{ id: String }` to trigger the registered callback.
///
/// Notes
/// - `enabled` for a leaf is true if `onSelected` or `onSelectedIntent` is present.
/// - Uses `FocusManager.instance.primaryFocus?.context` or the locked context to
///   resolve `Actions.find` / `Actions.invoke`.
/// - Intended to run on the UI isolate; keep lifecycle of the delegate aligned
///   with your app’s menu bar lifecycle.
///
/// Should be set in app's main function via
/// `WidgetsBinding.instance.platformMenuDelegate = EnhancedPlatformMenuDelegate();`
class EnhancedPlatformMenuDelegate extends PlatformMenuDelegate {
  BuildContext? _lockedContext;
  final Map<String, VoidCallback> _callbacks = {};

  EnhancedPlatformMenuDelegate() {
    attachChannelHandler();
  }

  final MethodChannel _channel = MethodChannel("enhanced_platform_menu");

  @override
  Future<void> setMenus(List<PlatformMenuItem> topLevelMenus) async {
    assert(() {
      _assertNoDuplicateShortcuts(topLevelMenus);
      return true;
    }());

    final payload = _serialize(topLevelMenus);
    await _channel.invokeMethod<void>('Menu.Set', payload);
  }

  @override
  Future<void> clearMenus() async => await _channel.invokeMethod<void>('Menu.Clear');

  @override
  bool debugLockDelegate(BuildContext context) {
    assert(() {
      if (_lockedContext != null && !identical(_lockedContext, context)) {
        return false;
      }
      _lockedContext = context;
      return true;
    }());
    return true;
  }

  @override
  bool debugUnlockDelegate(BuildContext context) {
    assert(() {
      if (_lockedContext != null && !identical(_lockedContext, context)) {
        return false;
      }
      _lockedContext = null;
      return true;
    }());
    return true;
  }

  Map<String, Object?> _serialize(List<PlatformMenuItem> menus) => {
    'menus': menus.map(_serializeItem).toList(),
  };

  Map<String, Object?> _serializeItem(PlatformMenuItem item) {
    if (item is PlatformMenu || item is EnhancedPlatformMenu) {
      final menus = item is PlatformMenu
          ? item.menus
          : item is EnhancedPlatformMenu
          ? item.menus
          : [];

      final children = <Map<String, Object?>>[];
      for (var i = 0; i < menus.length; i++) {
        final child = menus[i];

        if (child is PlatformMenuItemGroup) {
          for (final m in child.members) {
            children.add(_serializeItem(m));
          }
          final hasMore = i + 1 < menus.length;
          if (hasMore) children.add({'kind': 'separator'});
        } else {
          children.add(_serializeItem(child));
        }
      }

      return {
        'kind': 'menu',
        'label': item.label,
        'children': children,
        if (item is EnhancedPlatformMenu) 'identifier': item.identifier?.name,
        if (item is EnhancedPlatformMenu) 'removeDefaults': item.removeDefaultItems,
        if (item is EnhancedPlatformMenu && item.icon != null) ...item.icon!.serialize(),
      };
    }

    final id = UniqueKey().toString();
    final enabled = item.onSelectedIntent != null || item.onSelected != null;

    _callbacks[id] = () {
      final intent = item.onSelectedIntent;
      final context = FocusManager.instance.primaryFocus?.context ?? _lockedContext;

      if (intent != null && context != null) {
        final Action<Intent> action = Actions.find<Intent>(context, intent: intent);
        if (action.isEnabled(intent)) {
          Actions.invoke(context, intent);
          return;
        }
      }
      item.onSelected?.call();
    };

    return {
      'kind': 'leaf',
      'id': id,
      'label': item.label,
      'enabled': enabled,
      if (item.shortcut != null) 'shortcut': _shortcutToMap(item.shortcut),
      if (item is EnhancedPlatformMenuItem) 'checked': item.checked,
      if (item is EnhancedPlatformMenuItem && item.icon != null) ...item.icon!.serialize(),
    };
  }

  Map<String, Object?>? _shortcutToMap(MenuSerializableShortcut? shortcut) {
    if (shortcut == null) return null;
    final serializedShortcut = shortcut.serializeForMenu();
    return serializedShortcut.toChannelRepresentation();
  }

  void attachChannelHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'Menu.Selected') {
        final id = (call.arguments as Map)['id'] as String;
        _callbacks[id]?.call();
      }
    });
  }

  void _assertNoDuplicateShortcuts(List<PlatformMenuItem> topLevelMenus) {
    final seen = <String, String>{};

    void walk(List<PlatformMenuItem> items, String path) {
      for (final item in items) {
        if (item is PlatformMenu || item is EnhancedPlatformMenu) {
          final menus = item is PlatformMenu ? item.menus : (item as EnhancedPlatformMenu).menus;
          walk(menus, '$path/${item.label}');
          continue;
        }

        if (item is PlatformMenuItemGroup) {
          walk(item.members, path);
          continue;
        }

        final shortcut = item.shortcut;
        if (shortcut == null) continue;

        final key = _canonicalShortcutKey(shortcut);
        final here = '$path/${item.label}';

        final previous = seen[key];
        if (previous != null) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Duplicate menu shortcut detected.'),
            ErrorDescription('First:  $previous'),
            ErrorDescription('Second: $here'),
            ErrorHint(
              'Give each shortcut a unique key combo, or remove one of them. '
                  'If you intentionally want duplicates, add a whitelist mechanism.',
            ),
          ]);
        }

        seen[key] = here;
      }
    }

    walk(topLevelMenus, 'menubar');
  }

  String _canonicalShortcutKey(MenuSerializableShortcut shortcut) {
    if (shortcut is SingleActivator) {
      final triggerId = shortcut.trigger.keyId;

      final mods =
      (shortcut.meta ? 1 : 0) |
      (shortcut.control ? 2 : 0) |
      (shortcut.alt ? 4 : 0) |
      (shortcut.shift ? 8 : 0);

      return 'single:$mods:$triggerId';
    }

    if (shortcut is CharacterActivator) {
      final ch = shortcut.character;
      final mods =
      (shortcut.meta ? 1 : 0) |
      (shortcut.control ? 2 : 0) |
      (shortcut.alt ? 4 : 0);

      return 'char:$mods:${ch.codeUnits.join(",")}';
    }

    final rep = shortcut.serializeForMenu().toChannelRepresentation();
    return _stableJsonKey(rep);
  }

  String _stableJsonKey(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      final out = <String, Object?>{};
      for (final k in keys) {
        out[k] = _stableJsonKey(value[k]);
      }
      return 'map:$out';
    }
    if (value is List) {
      return 'list:${value.map(_stableJsonKey).toList()}';
    }
    return 'v:$value';
  }
}
