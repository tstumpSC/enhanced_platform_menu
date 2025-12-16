/// EnhancedPlatformMenuIcon (sealed)
/// ---------------------------------
/// Lightweight, serializable icon model for EnhancedPlatformMenus with two variants:
/// - `SFSymbolIcon(String name)`: references an SF Symbol by its system name
///   (macOS/iOS). Serializes as `{ 'symbol': name }`.
///   -> A collection of SF Symbol names can be found in sf_symbols.dart
/// - `AssetIcon(String path, {bool isMonochrome = true})`: references a Flutter
///   asset. Serializes as `{ 'asset': path, 'isMonochrome': true/false }`.
///   Assets can be PNG, JPG or PDF.
///
/// When to use
/// - Attach icons to menu items where the host platform can render SF Symbols or
///   app-provided assets. Use `isMonochrome` to hint platform-side tinting.
///
/// Example
/// ```dart
/// final sfIcon = EnhancedPlatformMenuIcon.sfSymbol(SFSymbols.sfs_0_circle);
/// final assetIcon = EnhancedPlatformMenuIcon.asset('assets/icons/export.png', isMonochrome: false);
/// ```
sealed class EnhancedPlatformMenuIcon {
  const EnhancedPlatformMenuIcon();

  const factory EnhancedPlatformMenuIcon.sfSymbol(String name) = SFSymbolIcon;

  const factory EnhancedPlatformMenuIcon.asset(
    String path, {
    bool isMonochrome,
  }) = AssetIcon;

  Map<String, dynamic> serialize() {
    return switch (this) {
      SFSymbolIcon(name: final n) => {'symbol': n},
      AssetIcon(:final path, :final isMonochrome) => {
        'asset': path,
        'isMonochrome': isMonochrome,
      },
    };
  }
}

class SFSymbolIcon extends EnhancedPlatformMenuIcon {
  final String name;

  const SFSymbolIcon(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SFSymbolIcon && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class AssetIcon extends EnhancedPlatformMenuIcon {
  final String path;
  final bool isMonochrome;

  const AssetIcon(this.path, {this.isMonochrome = true});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetIcon &&
          other.path == path &&
          other.isMonochrome == isMonochrome;

  @override
  int get hashCode => Object.hash(path, isMonochrome);
}
