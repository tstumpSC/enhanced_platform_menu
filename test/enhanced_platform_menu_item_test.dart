import 'package:enhanced_platform_menu/enhanced_platform_menu_icon.dart';
import 'package:enhanced_platform_menu/enhanced_platform_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockDelegate extends PlatformMenuDelegate {
  @override
  void clearMenus() {}

  @override
  bool debugLockDelegate(BuildContext context) => true;

  @override
  bool debugUnlockDelegate(BuildContext context) => true;

  @override
  void setMenus(List<PlatformMenuItem> topLevelMenus) {}
}

void main() {
  group('EnhancedPlatformMenu', () {
    test('standard() constructs with identifier, label, menus and equality works', () {
      final itemA = EnhancedPlatformMenuItem(label: 'Open');
      final itemB = EnhancedPlatformMenuItem(label: 'Close');
      final m1 = EnhancedPlatformMenu.standard(
        identifier: StandardMenuIdentifier.file,
        label: 'File',
        menus: [itemA, itemB],
        removeDefaultItems: true,
      );
      final m2 = EnhancedPlatformMenu.standard(
        identifier: StandardMenuIdentifier.file,
        label: 'File',
        menus: [itemA, itemB],
        removeDefaultItems: true,
      );

      expect(m1.identifier, StandardMenuIdentifier.file);
      expect(m1.menus, [itemA, itemB]);
      expect(m1.removeDefaultItems, isTrue);

      // equality/hashCode (menus list equality)
      expect(m1, equals(m2));
      expect(m1.hashCode, equals(m2.hashCode));
    });

    test('custom() constructs with icon and participates in equality/hash', () {
      final item = EnhancedPlatformMenuItem(label: 'Prefs');
      const icon = AssetIcon('assets/gear.png', isMonochrome: false);

      final m1 = EnhancedPlatformMenu.custom(label: 'Settings', menus: [item], icon: icon);
      final m2 = EnhancedPlatformMenu.custom(label: 'Settings', menus: [item], icon: icon);
      final m3 = EnhancedPlatformMenu.custom(
        label: 'Settings',
        menus: [item],
        icon: AssetIcon('assets/gear.png'),
      );

      expect(m1.icon, icon);
      expect(m1, equals(m2));
      expect(m1 == m3, isFalse); // icon mono flag differs
    });
  });

  group('EnhancedPlatformMenuItem', () {
    test('equality/hashCode include label, shortcut, checked, icon', () {
      final s = const SingleActivator(LogicalKeyboardKey.keyA, control: true);
      const i1 = SFSymbolIcon('bolt');
      const i2 = SFSymbolIcon('bolt');

      final a = EnhancedPlatformMenuItem(label: 'Do', shortcut: s, checked: true, icon: i1);
      final b = EnhancedPlatformMenuItem(label: 'Do', shortcut: s, checked: true, icon: i2);
      final c = EnhancedPlatformMenuItem(label: 'Do', shortcut: s, checked: false, icon: i1);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a == c, isFalse);
    });

    test('toChannelRepresentation emits checked flag, but no icon key (current impl)', () {
      final delegate = _MockDelegate();
      var nextId = 1;
      int idGen(PlatformMenuItem _) => nextId++;

      final item = EnhancedPlatformMenuItem(
        label: 'Toggle',
        checked: true,
        icon: const AssetIcon('assets/check.png'), // currently not serialized into map
      );

      final maps = item.toChannelRepresentation(delegate, getId: idGen).toList();

      // There should be exactly one serialized entry for a simple item.
      expect(maps.length, 1);
      expect(maps.first['checked'], true);
      // Assert current behavior: icon not added to map
      expect(maps.first.containsKey('icon'), isFalse);
    });

    test('toChannelRepresentation reflects checked=false', () {
      final delegate = _MockDelegate();
      int idGen(PlatformMenuItem _) => 1;

      final item = EnhancedPlatformMenuItem(label: 'Toggle', checked: false);
      final maps = item.toChannelRepresentation(delegate, getId: idGen).toList();
      expect(maps.first['checked'], false);
    });
  });

  group('EnhancedPlatformMenuItemGroup', () {
    test('equality/hashCode depend on members (list equality)', () {
      final a1 = EnhancedPlatformMenuItem(label: 'One');
      final a2 = EnhancedPlatformMenuItem(label: 'Two');

      final g1 = EnhancedPlatformMenuItemGroup(members: [a1, a2]);
      final g2 = EnhancedPlatformMenuItemGroup(members: [a1, a2]);
      final g3 = EnhancedPlatformMenuItemGroup(members: [a2, a1]);

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
      expect(g1 == g3, isFalse); // order matters in listEquals
    });
  });
}
