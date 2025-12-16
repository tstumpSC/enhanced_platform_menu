import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'enhanced_platform_menu_icon.dart';

/// EnhancedPlatformMenu & EnhancedPlatformMenuItem
/// -----------------------------------------------
/// A small extension layer over Flutter’s platform menu API that adds:
/// - **Top-level menus with identifiers** (`EnhancedPlatformMenu.standard`) to map
///   onto well-known system menus (e.g., File, Edit). On macOS you must provide
///   a custom `label` (asserted).
/// - **Custom top-level menus** (`EnhancedPlatformMenu.custom`) with optional
///   `EnhancedPlatformMenuIcon`.
/// - **Per-item enhancements** via `EnhancedPlatformMenuItem`:
///   - `checked`: renders a checkmark state where the host supports it.
///   - `icon`: attaches an `EnhancedPlatformMenuIcon` (SF Symbol or asset).
/// - **Item grouping** via `EnhancedPlatformMenuItemGroup` to cluster related
///   items; separators between groups are inserted by the delegate during
///   serialization.
///
/// Classes
/// - `EnhancedPlatformMenu extends PlatformMenuItem`
///   - `menus`: child `PlatformMenuItem`s (including groups/items/submenus).
///   - `identifier`: a `StandardMenuIdentifier` for system-mapped menus.
///   - `removeDefaultItems`: hint to strip OS-provided defaults when building a
///     standard menu (actual behavior is platform-dependent).
///   - `icon`: optional menu icon for custom menus.
/// - `StandardMenuIdentifier`: enumerates common system menus (e.g., `file`,
///   `edit`, `window`, `help`; `services` is macOS-only).
/// - `EnhancedPlatformMenuItem extends PlatformMenuItem`
///   - Adds `checked` and `icon`. Channel representation includes all base
///     fields plus `checked` and (if present) serialized icon data.
/// - `EnhancedPlatformMenuItemGroup extends PlatformMenuItemGroup`
///   - Groups multiple items
///
/// Example
/// ```dart
/// final fileMenu = EnhancedPlatformMenu.standard(
///   identifier: StandardMenuIdentifier.file,
///   label: 'File',
///   menus: [
///     EnhancedPlatformMenuItem(label: 'New', checked: false),
///     EnhancedPlatformMenuItemGroup(members: [
///       EnhancedPlatformMenuItem(label: 'Open…'),
///       EnhancedPlatformMenuItem(label: 'Close'),
///     ]),
///   ],
///   removeDefaultItems: true,
/// );
/// ```
class EnhancedPlatformMenu extends PlatformMenuItem {
  final List<PlatformMenuItem> menus;
  final StandardMenuIdentifier? identifier;
  final bool removeDefaultItems;
  final EnhancedPlatformMenuIcon? icon;

  const EnhancedPlatformMenu._({
    required super.label,
    required this.menus,
    this.identifier,
    this.removeDefaultItems = false,
    this.icon,
  });

  factory EnhancedPlatformMenu.standard({
    required StandardMenuIdentifier identifier,
    String? label,
    required List<PlatformMenuItem> menus,
    bool removeDefaultItems = false,
  }) {
    assert(
      !(Platform.isMacOS && label == null),
    ); // You need to provide your own label on macOS

    return EnhancedPlatformMenu._(
      label: label ?? "",
      menus: menus,
      identifier: identifier,
      removeDefaultItems: removeDefaultItems,
    );
  }

  factory EnhancedPlatformMenu.custom({
    required String label,
    required List<PlatformMenuItem> menus,
    EnhancedPlatformMenuIcon? icon,
  }) => EnhancedPlatformMenu._(label: label, menus: menus, icon: icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedPlatformMenu &&
          other.label == label &&
          other.identifier == identifier &&
          other.removeDefaultItems == removeDefaultItems &&
          other.icon == icon &&
          listEquals(other.menus, menus);

  @override
  int get hashCode => Object.hash(
    label,
    identifier,
    removeDefaultItems,
    icon,
    Object.hashAll(menus),
  );
}

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

class EnhancedPlatformMenuItem extends PlatformMenuItem {
  const EnhancedPlatformMenuItem({
    required super.label,
    super.onSelected,
    super.onSelectedIntent,
    super.shortcut,
    this.checked = false,
    this.icon,
  });

  final bool checked;
  final EnhancedPlatformMenuIcon? icon;

  @override
  Iterable<Map<String, Object?>> toChannelRepresentation(
    PlatformMenuDelegate delegate, {
    required MenuItemSerializableIdGenerator getId,
  }) sync* {
    for (final m in super.toChannelRepresentation(delegate, getId: getId)) {
      m['checked'] = checked;
      if (icon != null) icon!.serialize();
      yield m;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedPlatformMenuItem &&
          other.label == label &&
          other.shortcut == shortcut &&
          other.checked == checked &&
          other.icon == icon &&
          other.onSelectedIntent == onSelectedIntent;

  @override
  int get hashCode =>
      Object.hash(label, shortcut, checked, icon, onSelectedIntent);
}

class EnhancedPlatformMenuItemGroup extends PlatformMenuItemGroup {
  EnhancedPlatformMenuItemGroup({required super.members});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedPlatformMenuItemGroup &&
          listEquals(other.members, members);

  @override
  int get hashCode => Object.hashAll(members);
}
