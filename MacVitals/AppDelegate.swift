import AppKit
import ServiceManagement
import MacVitalsCore

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    /// There is no main nib, so `NSApplicationMain` would never create the delegate.
    /// `NSApplication.delegate` is weak, so the instance must outlive `run()`.
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var timer: Timer?
    private var cpuMeter = CPUMeter()
    private var cpuUsage: Double?
    private var memory: MemorySnapshot?

    private let launchAtLoginItem = NSMenuItem(title: String(localized: "Launch at Login"), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var displayItems: [NSMenuItem] = []
    private var intervalItems: [NSMenuItem] = []
    /// The fixed tail of the menu; the readings above it are rebuilt each time the menu opens.
    private var footer: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        Preferences.register()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        footer = makeFooter()
        _ = cpuMeter.sample()  // first sample only sets the baseline
        refresh()
        startTimer()
    }

    // MARK: Readings

    @objc private func refresh() {
        cpuUsage = cpuMeter.sample()
        memory = MemorySnapshot.read()
        statusItem.button?.attributedTitle = StatusBarTitle.make(memory: memory, cpuUsage: cpuUsage)
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = Preferences.refreshInterval
        let timer = Timer(timeInterval: interval, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timer.tolerance = interval / 5
        RunLoop.main.add(timer, forMode: .common)  // keeps updating while the menu is open
        self.timer = timer
    }

    // MARK: Menu

    func menuWillOpen(_ menu: NSMenu) {
        var items: [NSMenuItem] = []
        func section(_ title: String) {
            if !items.isEmpty { items.append(.separator()) }
            items.append(.sectionHeader(title: title))
        }
        func row(_ label: String, _ value: String) {
            let item = NSMenuItem(title: label, action: nil, keyEquivalent: "")
            item.badge = NSMenuItemBadge(string: value)
            items.append(item)
        }

        if let memory {
            section(String(localized: "Memory"))
            row(String(localized: "Used"), "\(ByteFormat.memory(memory.used)) / \(ByteFormat.memory(memory.total))")
            row(String(localized: "Available"), ByteFormat.memory(memory.available))
            row(String(localized: "File cache"), ByteFormat.memory(memory.fileCache))
            row(String(localized: "Compressed"), ByteFormat.memory(memory.compressed))
            row(String(localized: "Swap"), "\(ByteFormat.memory(memory.swapUsed)) / \(ByteFormat.memory(memory.swapTotal))")
            row(String(localized: "Pressure"), Self.name(of: memory.pressure))
        }

        section(String(localized: "CPU"))
        row(String(localized: "Usage"), cpuUsage.map(ByteFormat.percentage) ?? "…")
        if let (one, five, fifteen) = CPUMeter.loadAverage() {
            row(String(localized: "Load 1/5/15 min"), String(format: "%.1f  %.1f  %.1f", one, five, fifteen))
        }

        if let disk = DiskSnapshot.read() {
            section(String(localized: "Disk"))
            row(String(localized: "Used"), "\(ByteFormat.disk(disk.used)) / \(ByteFormat.disk(disk.total))")
            row(String(localized: "Free"), ByteFormat.disk(disk.free))
        }

        let apps = ProcessMemory.topApps(5)
        if !apps.isEmpty {
            section(String(localized: "Memory by app"))
            for app in apps {
                let processes = app.processCount == 1
                    ? String(localized: "1 process")
                    : String(localized: "\(app.processCount) processes")
                row("\(app.name) · \(processes)", ByteFormat.memory(app.residentBytes))
            }
        }

        for item in displayItems { item.state = Preferences.bool(item.representedObject as! String) ? .on : .off }
        for item in intervalItems { item.state = item.representedObject as! TimeInterval == Preferences.refreshInterval ? .on : .off }
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off

        menu.items = items + footer
    }

    private func makeFooter() -> [NSMenuItem] {
        displayItems = [
            (String(localized: "Memory"), Preferences.Key.showsMemory),
            (String(localized: "Swap"), Preferences.Key.showsSwap),
            (String(localized: "CPU"), Preferences.Key.showsCPU),
        ].map { title, key in
            let item = NSMenuItem(title: title, action: #selector(toggleDisplay), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            return item
        }
        intervalItems = Preferences.intervals.map { interval in
            let item = NSMenuItem(title: String(localized: "\(Int(interval)) seconds"), action: #selector(chooseInterval), keyEquivalent: "")
            item.target = self
            item.representedObject = interval
            return item
        }
        launchAtLoginItem.target = self

        let settingsItems: [NSMenuItem] = [
            submenu(String(localized: "Show in Menu Bar"), displayItems),
            submenu(String(localized: "Refresh Every"), intervalItems),
            .separator(),
            launchAtLoginItem,
        ]

        let activityMonitor = NSMenuItem(title: String(localized: "Open Activity Monitor"), action: #selector(openActivityMonitor), keyEquivalent: "")
        let about = NSMenuItem(title: String(localized: "About MacVitals"), action: #selector(showAbout), keyEquivalent: "")
        let quit = NSMenuItem(title: String(localized: "Quit MacVitals"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        activityMonitor.target = self
        about.target = self
        return [.separator(), activityMonitor, submenu(String(localized: "Settings"), settingsItems), about, quit]
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        menu.autoenablesItems = false
        menu.items = items
        item.submenu = menu
        return item
    }

    private static func name(of pressure: MemoryPressure) -> String {
        switch pressure {
        case .normal: String(localized: "Normal")
        case .warning: String(localized: "Warning")
        case .critical: String(localized: "Critical")
        }
    }

    // MARK: Actions

    @objc private func toggleDisplay(_ sender: NSMenuItem) {
        Preferences.toggle(sender.representedObject as! String)
        refresh()
    }

    @objc private func chooseInterval(_ sender: NSMenuItem) {
        Preferences.refreshInterval = sender.representedObject as! TimeInterval
        startTimer()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSSound.beep()
        }
    }

    @objc private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    @objc private func showAbout() {
        NSApp.activate()  // a menu bar app has no key window, so the panel would otherwise open behind others
        NSApp.orderFrontStandardAboutPanel(options: [
            .credits: NSAttributedString(
                string: String(localized: "Free software under the GNU General Public License v3."),
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize), .foregroundColor: NSColor.labelColor]
            ),
        ])
    }
}
