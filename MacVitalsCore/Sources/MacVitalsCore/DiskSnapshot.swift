import Foundation

/// Capacity of the startup volume, in bytes. "Free" is what the system would let an important download use.
public struct DiskSnapshot: Sendable {
    public let used: UInt64
    public let free: UInt64
    public let total: UInt64

    public static func read(volume: URL = URL(fileURLWithPath: "/")) -> DiskSnapshot? {
        let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
        guard let values = try? volume.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacityForImportantUsage,
              total > 0, free >= 0, Int64(total) >= free
        else { return nil }
        return DiskSnapshot(used: UInt64(Int64(total) - free), free: UInt64(free), total: UInt64(total))
    }
}
