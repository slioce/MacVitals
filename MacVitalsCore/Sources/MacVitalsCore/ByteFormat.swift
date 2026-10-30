import Foundation

public enum ByteFormat {
    /// Short form for the menu bar: "5.2G" from one gigabyte up, whole megabytes below.
    public static func compact(_ bytes: UInt64) -> String {
        bytes >= 1 << 30
            ? String(format: "%.1fG", Double(bytes) / Double(1 << 30))
            : "\(bytes >> 20)M"
    }

    /// Memory sizes for the menu, like "5.2 GB" or "512 MB".
    public static func memory(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useMB, .useGB]
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Disk sizes for the menu, in the decimal gigabytes Finder uses: one decimal below 100 GB, none above.
    public static func disk(_ bytes: UInt64) -> String {
        let gigabytes = Double(bytes) / 1e9
        return gigabytes.formatted(.number.precision(.fractionLength(gigabytes < 100 ? 1 : 0))) + " GB"
    }

    public static func percentage(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }
}
