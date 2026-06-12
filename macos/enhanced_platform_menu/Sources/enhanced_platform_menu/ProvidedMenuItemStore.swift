import Cocoa

/// Stores copies of the "platform provided" menu items from the app's existing main menu,
/// and allows looking them up by semantic type (e.g. "about", "quit", "hide").
///
/// This mirrors how Flutter's macOS menu plugin works: it does not generate localized titles;
/// it clones items from the existing NSApp.mainMenu.
final class ProvidedMenuItemStore {
    enum ProvidedType: String {
        case about
        case quit
        case hide
        case hideOtherApplications
        case showAllApplications
        case startSpeaking
        case stopSpeaking
        case toggleFullScreen
        case minimizeWindow
        case zoomWindow
        case arrangeWindowsInFront
    }

    /// Cached top-level items copied from the main menu.
    /// We keep the whole tree so we can search it later.
    private var cachedTopLevelItems: [NSMenuItem] = []

    func snapshot(from menu: NSMenu) {
        cachedTopLevelItems = menu.items.compactMap { $0.copy() as? NSMenuItem }
        replaceAppNamePlaceholders(in: cachedTopLevelItems)
    }

    /// Call once after the main menu is constructed (e.g. after didFinishLaunching).
    func snapshotFromCurrentMainMenu() {
        guard let main = NSApp.mainMenu else { return }
        snapshot(from: main)
    }

    /// Returns a *copy* of the platform-provided menu item for the given type.
    /// If not found, returns nil.
    func menuItem(for typeString: String) -> NSMenuItem? {
        guard let type = ProvidedType(rawValue: typeString) else { return nil }
        return menuItem(for: type)
    }

    /// Returns a *copy* of the platform-provided menu item for the given type.
    /// If not found, returns nil.
    func menuItem(for type: ProvidedType) -> NSMenuItem? {
        guard let selector = selector(for: type) else { return nil }

        // Find by selector in the cached tree
        if let found = findFirstItem(withAction: selector, in: cachedTopLevelItems) {
            return found.copy() as? NSMenuItem
        }

        return nil
    }

    /// Whether we currently have any cached provided items.
    var hasSnapshot: Bool {
        !cachedTopLevelItems.isEmpty
    }

    private func selector(for type: ProvidedType) -> Selector? {
        switch type {
        case .about:
            return #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        case .quit:
            return #selector(NSApplication.terminate(_:))
        case .hide:
            return #selector(NSApplication.hide(_:))
        case .hideOtherApplications:
            return #selector(NSApplication.hideOtherApplications(_:))
        case .showAllApplications:
            return #selector(NSApplication.unhideAllApplications(_:))
        case .startSpeaking:
            return #selector(NSTextView.startSpeaking(_:))
        case .stopSpeaking:
            return #selector(NSTextView.stopSpeaking(_:))
        case .toggleFullScreen:
            return #selector(NSWindow.toggleFullScreen(_:))
        case .minimizeWindow:
            return #selector(NSWindow.performMiniaturize(_:))
        case .zoomWindow:
            return #selector(NSWindow.performZoom(_:))
        case .arrangeWindowsInFront:
            return #selector(NSApplication.arrangeInFront(_:))
        }
    }

    private func findFirstItem(withAction selector: Selector, in items: [NSMenuItem]) -> NSMenuItem? {
        for item in items {
            if item.action == selector {
                return item
            }
            if let submenu = item.submenu,
            let found = findFirstItem(withAction: selector, in: submenu.items) {
                return found
            }
        }
        return nil
    }

    private func findFirstItem(where predicate: (NSMenuItem) -> Bool, in items: [NSMenuItem]) -> NSMenuItem? {
        for item in items {
            if predicate(item) { return item }
            if let submenu = item.submenu,
            let found = findFirstItem(where: predicate, in: submenu.items) {
                return found
            }
        }
        return nil
    }

    /// Flutter's templates historically used "APP_NAME" placeholders in some titles.
    /// This replaces it with the actual process name.
    private func replaceAppNamePlaceholders(in items: [NSMenuItem]) {
        let appName = ProcessInfo.processInfo.processName

        for item in items {
            if item.title.contains("APP_NAME") {
                item.title = item.title.replacingOccurrences(of: "APP_NAME", with: appName)
            }
            if let submenu = item.submenu {
                replaceAppNamePlaceholders(in: submenu.items)
            }
        }
    }
}
