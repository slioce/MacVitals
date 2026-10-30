import Darwin

/// CPU usage as the share of busy ticks between two consecutive samples.
public struct CPUMeter: Sendable {
    struct Ticks {
        var busy: UInt64
        var total: UInt64
    }

    private var previous: Ticks?

    public init() {}

    /// Percentage of CPU in use since the previous call; nil on the first call or when no time has passed.
    public mutating func sample() -> Double? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let (user, system, idle, nice) = info.cpu_ticks
        let busy = UInt64(user) + UInt64(system) + UInt64(nice)
        return record(Ticks(busy: busy, total: busy + UInt64(idle)))
    }

    mutating func record(_ ticks: Ticks) -> Double? {
        defer { previous = ticks }
        guard let previous, ticks.total > previous.total else { return nil }
        return Double(ticks.busy - previous.busy) / Double(ticks.total - previous.total) * 100
    }

    /// Load average over the last 1, 5 and 15 minutes.
    public static func loadAverage() -> (Double, Double, Double)? {
        var loads = [Double](repeating: 0, count: 3)
        guard getloadavg(&loads, 3) == 3 else { return nil }
        return (loads[0], loads[1], loads[2])
    }
}
