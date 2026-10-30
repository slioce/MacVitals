import AppKit
import MacVitalsCore

/// The text in the menu bar: a dot colored by memory pressure, then the readings the user chose to show.
@MainActor
enum StatusBarTitle {
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    /// Swap below this size is noise left behind by the system rather than pressure.
    private static let swapThreshold: UInt64 = 64 << 20

    static func make(memory: MemorySnapshot?, cpuUsage: Double?) -> NSAttributedString {
        let title = NSMutableAttributedString(string: "●", attributes: [.font: font, .foregroundColor: color(for: memory?.pressure)])
        var parts: [String] = []
        if let memory {
            if Preferences.bool(Preferences.Key.showsMemory) { parts.append(ByteFormat.compact(memory.used)) }
            if Preferences.bool(Preferences.Key.showsSwap), memory.swapUsed > swapThreshold {
                parts.append("⇅" + ByteFormat.compact(memory.swapUsed))
            }
        }
        if Preferences.bool(Preferences.Key.showsCPU), let cpuUsage { parts.append(ByteFormat.percentage(cpuUsage)) }
        if !parts.isEmpty {
            title.append(NSAttributedString(string: " " + parts.joined(separator: " "), attributes: [.font: font]))
        }
        return title
    }

    private static func color(for pressure: MemoryPressure?) -> NSColor {
        switch pressure {
        case .critical: .systemRed
        case .warning: .systemYellow
        case .normal: .systemGreen
        case nil: .secondaryLabelColor
        }
    }
}
