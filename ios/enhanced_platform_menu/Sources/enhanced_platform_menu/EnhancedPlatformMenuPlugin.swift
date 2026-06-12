import Flutter
import UIKit
import ObjectiveC.runtime

public class EnhancedPlatformMenuPlugin: NSObject, FlutterPlugin {
    private static var instance: EnhancedPlatformMenuPlugin?
    private var channel: FlutterMethodChannel!
    private var cachedMenus: [[String: Any]] = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "enhanced_platform_menu", binaryMessenger: registrar.messenger())
        let inst = EnhancedPlatformMenuPlugin(channel: channel)
        registrar.addMethodCallDelegate(inst, channel: channel)
        instance = inst
        
        Swizzler.install()
    }
    
    private init(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    @objc public static func shared() -> EnhancedPlatformMenuPlugin? { instance }
    
    @objc public func onMenuItemSelected(id: String) {
        channel.invokeMethod("Menu.Selected", arguments: ["id": id])
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "Menu.Set":
            guard let root = call.arguments as? [String: Any],
                  let items = root["menus"] as? [[String: Any]] else {
                result(FlutterError(code: "bad_args", message: "menus missing", details: nil)); return
            }
            Task { @MainActor in
                self.cachedMenus = items
                self.requestRebuild()
            }
            result(nil)
            
        case "Menu.Clear":
            Task { @MainActor in
                self.cachedMenus = []
                self.requestRebuild()
            }
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Called from the swizzled buildMenu
    @objc public func augmentMenu(with builder: UIMenuBuilder) {
        guard builder.system == .main, !cachedMenus.isEmpty else { return }
        
        func toUIKitId(_ id: String) -> UIMenu.Identifier? {
            switch id {
            case "application": return .application
            case "file":        return .file
            case "edit":        return .edit
            case "format":      return .format
            case "view":        return .view
            case "window":      return .window
            case "help":        return .help
            default:            return nil
            }
        }
        
        // Presence map for standard menus from Flutter
        let present = Set(cachedMenus.compactMap { $0["identifier"] as? String })
        
        // Remove any standard menus not provided by Flutter (except .application)
        for key in ["file","edit","format","view"] where !present.contains(key) {
            if let id = toUIKitId(key) { builder.remove(menu: id) }
        }
        
        // Choose the Application menu source (explicit "application" or fallback to first)
        let appIdx = cachedMenus.firstIndex { ($0["identifier"] as? String) == "application" } ?? 0
        if let kids = makeChildren(fromTopLevelMenuMap: cachedMenus[appIdx]), !kids.isEmpty {
            let group = UIMenu(title: "", options: [.displayInline], children: kids)
            builder.insertChild(group, atStartOfMenu: .application)
        }
        
        // Process the rest
        for (idx, map) in cachedMenus.enumerated() where idx != appIdx {
            let id  = map["identifier"] as? String
            let rm  = (map["removeDefaults"] as? Bool) ?? false
            
            if let std = id, let anchor = toUIKitId(std) {
                // Standard menus
                if rm { builder.replaceChildren(ofMenu: anchor) { _ in [] } }  // wipe defaults if requested
                
                if let kids = makeChildren(fromTopLevelMenuMap: map), !kids.isEmpty {
                    let block = UIMenu(title: "", options: [.displayInline], children: kids)
                    switch anchor {
                    case .window, .help: builder.insertChild(block, atStartOfMenu: anchor)
                    default:             builder.insertChild(block, atEndOfMenu: anchor)
                    }
                }
            } else {
                // Custom top-level → place before Window
                if let top = makeTopMenu(from: map) {
                    builder.remove(menu: top.identifier)
                    builder.insertSibling(top, beforeMenu: .window)
                }
            }
        }
    }
    
    
    @MainActor
    private func requestRebuild(structure: Bool = true) {
        if structure {
            UIMenuSystem.main.setNeedsRebuild()
        } else {
            if #available(iOS 14.0, *) {
                UIMenuSystem.main.setNeedsRevalidate()
            } else {
                UIMenuSystem.main.setNeedsRebuild()
            }
        }
    }
    
    private func makeChildren(fromTopLevelMenuMap map: [String: Any]) -> [UIMenuElement]? {
        guard (map["kind"] as? String) == "menu",
              let kids = map["children"] as? [[String: Any]] else { return nil }
        return buildChildrenWithSeparators(kids)
    }
    
    private func buildChildrenWithSeparators(_ kids: [[String: Any]]) -> [UIMenuElement] {
        var sections: [[UIMenuElement]] = []
        var current: [UIMenuElement] = []
        
        for k in kids {
            if (k["kind"] as? String) == "separator" {
                if !current.isEmpty { sections.append(current); current.removeAll() }
            } else if let el = makeElement(from: k) {
                current.append(el)
            }
        }
        if !current.isEmpty { sections.append(current) }
        
        var out: [UIMenuElement] = []
        if let first = sections.first { out.append(contentsOf: first) }
        for s in sections.dropFirst() {
            out.append(UIMenu(title: "", options: .displayInline, children: s))
        }
        return out
    }
    
    private func makeTopMenu(from map: [String: Any]) -> UIMenu? {
        guard (map["kind"] as? String) == "menu" else { return nil }
        let title = (map["label"] as? String) ?? ""
        let childrenMaps = (map["children"] as? [[String: Any]]) ?? []
        let children = buildChildrenWithSeparators(childrenMaps)
        
        let stableId: String = {
            if let explicit = map["id"] as? String, !explicit.isEmpty { return explicit }
            return "menu.\(sanitizeId(title))"
        }()
        
        return UIMenu(title: title,
                      image: {
            if let sym = map["symbol"] as? String { return UIImage(systemName: sym) }
            if let asset = map["asset"]  as? String { return UIImage(named: asset) }
            return nil
        }(),
                      identifier: UIMenu.Identifier(stableId),
                      options: [],
                      children: children)
    }
    
    private func makeElement(from map: [String: Any]) -> UIMenuElement? {
        guard let kind = map["kind"] as? String else { return nil }
        switch kind {
        case "menu":
            return makeTopMenu(from: map)
            
        case "leaf":
            let title   = map["label"] as? String ?? ""
            let id      = map["id"] as? String ?? UUID().uuidString
            let enabled = (map["enabled"] as? Bool) ?? true
            let checked = (map["checked"] as? Bool) ?? false
            
            var image: UIImage? = nil
            if let sym = map["symbol"] as? String {
                image = UIImage(systemName: sym)?.withRenderingMode(.alwaysTemplate)
            } else if let asset = map["asset"] as? String {
                let template = (map["isMonochrome"] as? Bool) ?? true
                image = uiImageFromFlutterAsset(asset, template: template)
            }

            if let shortcut = map["shortcut"] as? [String: Any],
let (input, mods) = safeKeyTuple(shortcut) {

// With keyboard shortcut → UIKeyCommand
let cmd = UIKeyCommand(
title: title,
image: image,
action: #selector(UIResponder.handleKeyCommand(_:)),
input: input,
modifierFlags: mods,
propertyList: id
)

cmd.discoverabilityTitle = title
cmd.state = checked ? .on : .off
if !enabled { cmd.attributes.insert(.disabled) }
return cmd

} else {

// No keyboard shortcut → UICommand (still searchable/discoverable)
let cmd = UICommand(
title: title,
image: image,
action: #selector(UIResponder.handleKeyCommand(_:)),
propertyList: id
)

cmd.discoverabilityTitle = title
cmd.state = checked ? .on : .off
if !enabled { cmd.attributes.insert(.disabled) }
return cmd
}
            
        default:
            return nil
        }
    }
    
    private func safeKeyTuple(_ s: [String: Any]) -> (String, UIKeyModifierFlags)? {
        if let n = s["shortcutTrigger"] as? NSNumber,
           let scalar = UnicodeScalar(n.intValue),
           (0x20...0x7E).contains(Int(scalar.value)) {
            let input = String(Character(scalar)).lowercased()
            var mods: UIKeyModifierFlags = []
            if let m = s["shortcutModifiers"] as? NSNumber {
                let bm = m.intValue // 1=⌘, 2=⇧, 4=⌥, 8=⌃
                if (bm & 1) != 0 { mods.insert(.command) }
                if (bm & 2) != 0 { mods.insert(.shift) }
                if (bm & 4) != 0 { mods.insert(.alternate) }
                if (bm & 8) != 0 { mods.insert(.control) }
            }
            return (input, mods)
        }
        
        if let ch = s["character"] as? String, ch.count == 1 {
            let input = ch.lowercased()
            var mods: UIKeyModifierFlags = []
            if (s["meta"]    as? Bool) == true { mods.insert(.command) }
            if (s["shift"]   as? Bool) == true { mods.insert(.shift) }
            if (s["alt"]     as? Bool) == true { mods.insert(.alternate) }
            if (s["control"] as? Bool) == true { mods.insert(.control) }
            return (input, mods)
        }
        return nil
    }
    
    private func sanitizeId(_ title: String) -> String {
        let lowered = title.lowercased()
        let hyphenated = lowered.replacingOccurrences(of: "[^a-z0-9_-]+",
                                                      with: "-",
                                                      options: .regularExpression)
        let trimmed = hyphenated.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "untitled" : trimmed
    }
    
    private var uiImageCache = NSCache<NSString, UIImage>()
    
    private func uiImageFromFlutterAsset(_ assetPath: String,
                                         template: Bool = true) -> UIImage? {
        let cacheKey = "\(assetPath)|\(template)" as NSString
        if let cached = uiImageCache.object(forKey: cacheKey) { return cached }
        
        let key = FlutterDartProject.lookupKey(forAsset: assetPath)
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else { return nil }
        let ext = (path as NSString).pathExtension.lowercased()
        
        var img: UIImage?
        switch ext {
        case "png", "jpg", "jpeg":
            img = UIImage(contentsOfFile: path)
        case "pdf":
            img = rasterizePDF(atPath: path)
        default:
            if ext == "svg" {
                NSLog("enhanced_platform_menu: SVG not supported; use PNG, JPG or PDF — %@", path)
            }
        }
        
        guard var out = img else { return nil }
        out = template ? out.withRenderingMode(.alwaysTemplate)
        : out.withRenderingMode(.alwaysOriginal)
        uiImageCache.setObject(out, forKey: cacheKey)
        return out
    }
    
    private func rasterizePDF(atPath path: String) -> UIImage? {
        guard
            let data = NSData(contentsOfFile: path) as Data?,
            let provider = CGDataProvider(data: data as CFData),
            let pdf = CGPDFDocument(provider),
            let page = pdf.page(at: 1)
        else { return nil }
        
        let pointSize = CGFloat(17)
        let box = page.getBoxRect(.mediaBox)
        let scale = min(pointSize / box.width, pointSize / box.height)
        let size = CGSize(width: box.width * scale, height: box.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            ctx.cgContext.drawPDFPage(page)
        }
    }
}

private enum Swizzler {
    static func install() {
        if #available(iOS 13.0, *) {
            guard let original = class_getInstanceMethod(UIResponder.self, #selector(UIResponder.buildMenu(with:))),
                  let swizzled = class_getInstanceMethod(UIResponder.self, #selector(UIResponder.epm_buildMenu(with:))) else {
                return
            }
            method_exchangeImplementations(original, swizzled)
        }
    }
}

extension UIResponder {
    @objc func handleKeyCommand(_ sender: UICommand) {
        if let id = sender.propertyList as? String {
            EnhancedPlatformMenuPlugin.shared()?.onMenuItemSelected(id: id)
        }
    }
    
    @objc func epm_buildMenu(with builder: UIMenuBuilder) {
        // call original first
        self.epm_buildMenu(with: builder)
        // then your augmentation
        EnhancedPlatformMenuPlugin.shared()?.augmentMenu(with: builder)
    }
}
