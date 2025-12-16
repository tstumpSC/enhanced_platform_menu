import Cocoa
import FlutterMacOS

public class EnhancedPlatformMenuPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel!
    private var cachedMenus: [[String: Any]] = []
    private static var registrar: FlutterPluginRegistrar?
    private var didSetServicesMenu = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        EnhancedPlatformMenuPlugin.registrar = registrar
        
        let channel = FlutterMethodChannel(name: "enhanced_platform_menu", binaryMessenger: registrar.messenger)
        let instance = EnhancedPlatformMenuPlugin(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "Menu.Set":
            guard let root = call.arguments as? [String: Any],
                  let items = root["menus"] as? [[String: Any]] else {
                result(FlutterError(code: "bad_args", message: "menus missing", details: nil))
                return
            }
            
            Task { @MainActor in
                self.rebuildMainMenu(items: items)
                result(nil)
            }
            
        case "Menu.Clear":
            Task { @MainActor in
                self.clearMainMenu()
                result(nil)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @MainActor private func clearMainMenu() {
        NSApplication.shared.mainMenu = NSMenu()
        NSApp.servicesMenu = nil
        NSApp.windowsMenu = nil
        NSApp.helpMenu = nil
    }
    
    @MainActor private func rebuildMainMenu(items: [[String: Any]]) {
        cachedMenus = items
        
        // 1) Stable sort into the desired order, customs between View and Services.
        let rank: [String: Int] = [
            "application": 0,
            "file":        1,
            "edit":        2,
            "format":      3,
            "view":        4,
            // customs use 5
            "services":    6,
            "window":      7,
            "help":        8,
        ]
        let CUSTOM_BUCKET = 5
        
        // tag each with (rank, originalIndex) to keep order stable within buckets
        let sortedTop: [[String: Any]] = items.enumerated()
            .map { (idx, map) -> (Int, Int, [String: Any]) in
                let id = map["identifier"] as? String
                let r  = id.flatMap { rank[$0] } ?? CUSTOM_BUCKET
                return (r, idx, map)
            }
            .sorted { (a, b) -> Bool in
                if a.0 != b.0 { return a.0 < b.0 }
                return a.1 < b.1
            }
            .map { $0.2 }
        
        let main = NSMenu(title: "Main")
        main.autoenablesItems = false
        
        // Clear role pointers; we’ll re-assign below.
        didSetServicesMenu = false
        NSApp.servicesMenu = nil
        NSApp.windowsMenu = nil
        NSApp.helpMenu = nil
        
        for map in sortedTop {
            guard let mi = makeMenuItem(from: map) else { continue }
            main.addItem(mi)
            
            if let identifier = map["identifier"] as? String, let sub = mi.submenu {
                switch identifier {
                case "services":
                    NSApp.servicesMenu = sub
                case "window":
                    NSApp.windowsMenu = sub
                case "help":
                    NSApp.helpMenu = sub
                default:
                    break
                }
            }
        }
        
        NSApp.mainMenu = main
    }
    
    @MainActor private func makeMenuItem(from map: [String: Any]) -> NSMenuItem? {
        guard let kind = map["kind"] as? String else { return nil }
        
        switch kind {
        case "separator":
            return NSMenuItem.separator()
            
        case "menu":
            let title = (map["label"] as? String) ?? ""
            let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: title)
            submenu.autoenablesItems = false
            
            // If this submenu is the Services submenu, wire it — even when nested.
            if let ident = map["identifier"] as? String, ident == "services", !didSetServicesMenu {
                NSApp.servicesMenu = submenu
                didSetServicesMenu = true
                if #available(macOS 11.0, *),
                   let gear = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil) {
                    gear.isTemplate = true
                    parent.image = gear
                }
            } else {
                if let sym = map["symbol"] as? String {
                    if #available(macOS 11.0, *),
                       let img = NSImage(systemSymbolName: sym, accessibilityDescription: nil) {
                        img.isTemplate = true
                        parent.image = img
                    }
                } else if let asset = map["asset"] as? String {
                    let template = (map["isMonochrome"] as? Bool) ?? true
                    if let img = nsImageFromFlutterAsset(asset, template: template) {
                        parent.image = img
                    }
                }
            }
            
            if let children = map["children"] as? [[String: Any]] {
                for child in children {
                    if let c = makeMenuItem(from: child) { submenu.addItem(c) }
                }
            }
            
            parent.submenu = submenu
            return parent
            
        case "leaf":
            let title = (map["label"] as? String) ?? ""
            let id = (map["id"] as? String) ?? UUID().uuidString
            
            let item = NSMenuItem(title: title,
                                  action: #selector(onSelect(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.representedObject = id
            
            if let enabled = map["enabled"] as? Bool { item.isEnabled = enabled }
            if let checked = map["checked"] as? Bool { item.state = checked ? .on : .off }
            
            if let shortcut = map["shortcut"] as? [String: Any] { applyShortcut(shortcut, to: item) }
            
            if let sym = map["symbol"] as? String {
                if #available(macOS 11.0, *),
                   let img = NSImage(systemSymbolName: sym, accessibilityDescription: nil) {
                    img.isTemplate = true
                    item.image = img
                }
            } else if let asset = map["asset"] as? String {
                let template = (map["isMonochrome"] as? Bool) ?? true
                if let img = nsImageFromFlutterAsset(asset, template: template) {
                    item.image = img
                }
            }
            return item
            
        default:
            return nil
        }
    }
    
    @objc private func onSelect(_ sender: Any?) {
        guard let id = (sender as? NSMenuItem)?.representedObject as? String else { return }
        channel.invokeMethod("Menu.Selected", arguments: ["id": id])
    }
    
    @MainActor private func applyShortcut(_ s: [String: Any], to item: NSMenuItem) {
        if let trig = s["shortcutTrigger"] as? NSNumber,
           let scalar = UnicodeScalar(trig.intValue),
           (0x20...0x7E).contains(Int(scalar.value)) {
            item.keyEquivalent = String(Character(scalar)).lowercased()
        } else if let ch = s["character"] as? String, !ch.isEmpty {
            item.keyEquivalent = String(ch.prefix(1)).lowercased()
        } else {
            item.keyEquivalent = ""
        }
        
        var mods: NSEvent.ModifierFlags = []
        if let m = s["shortcutModifiers"] as? NSNumber {
            let bm = m.intValue
            if (bm & 1) != 0 { mods.insert(.command) }
            if (bm & 2) != 0 { mods.insert(.shift) }
            if (bm & 4) != 0 { mods.insert(.option) }
            if (bm & 8) != 0 { mods.insert(.control) }
        } else {
            if (s["meta"]    as? Bool) == true { mods.insert(.command) }
            if (s["shift"]   as? Bool) == true { mods.insert(.shift) }
            if (s["alt"]     as? Bool) == true { mods.insert(.option) }
            if (s["control"] as? Bool) == true { mods.insert(.control) }
        }
        item.keyEquivalentModifierMask = mods
    }
    
    private let imageCache = NSCache<NSString, NSImage>()
    
    private func aspectFit(_ size: NSSize, max: CGFloat) -> NSSize {
        guard size.width > 0, size.height > 0 else { return NSSize(width: max, height: max) }
        let s = min(max / size.width, max / size.height)
        return NSSize(width: round(size.width * s), height: round(size.height * s))
    }
    
    private func nsImageFromFlutterAsset(_ assetPath: String,
                                         template: Bool = true
    ) -> NSImage? {
        guard let path = resolveFlutterAssetPath(assetPath) else { return nil }
        
        let cacheKey = "\(path)|tpl:\(template)" as NSString
        if let cached = imageCache.object(forKey: cacheKey) { return cached }
        
        let ext = (path as NSString).pathExtension.lowercased()
        let base: NSImage? = {
            switch ext {
            case "png", "jpg", "jpeg":
                return NSImage(contentsOfFile: path)
            case "pdf":
                if let data = NSData(contentsOfFile: path) as Data?,
                   let rep = NSPDFImageRep(data: data) {
                    let v = NSImage(size: rep.size)
                    v.addRepresentation(rep)
                    return v
                }
                return nil
            default:
                return NSImage(contentsOfFile: path)
            }
        }()
        
        guard let src = base else { return nil }
        
        let copy = src.copy() as? NSImage ?? NSImage(size: src.size)
        if copy != src, copy.representations.isEmpty {
            copy.addRepresentations(src.representations)
        }
        
        copy.size = aspectFit(copy.size, max: 17)
        copy.isTemplate = template
        
        imageCache.setObject(copy, forKey: cacheKey)
        return copy
    }
    
    private func resolveFlutterAssetPath(_ asset: String) -> String? {
        let fm = FileManager.default
        
        // 1) Absolute path already?
        if asset.hasPrefix("/"), fm.fileExists(atPath: asset) {
            return asset
        }
        
        // 2) Compute the logical key:
        //    - If it already starts with "packages/", use it as-is.
        //    - Else ask Flutter for the key (works for app assets).
        let key: String = {
            if asset.hasPrefix("packages/") {
                return asset
            } else {
                return FlutterDartProject.lookupKey(forAsset: asset)
            }
        }()
        
        // 3) Try the canonical macOS location:
        //    Contents/Frameworks/App.framework/Resources/flutter_assets/<key>
        if let fa = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Frameworks", isDirectory: true)
            .appendingPathComponent("App.framework", isDirectory: true)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("flutter_assets", isDirectory: true) as URL? {
            let candidate = fa.appendingPathComponent(key).path
            if fm.fileExists(atPath: candidate) { return candidate }
        }
        
        // 4) Fallback: sometimes Flutter also exposes resources directly to the bundle
        if let p = Bundle.main.path(forResource: key, ofType: nil), fm.fileExists(atPath: p) {
            return p
        }
        
        NSLog("enhanced_platform_menu: asset not found (asset=%@, key=%@)", asset, key)
        return nil
    }
}
