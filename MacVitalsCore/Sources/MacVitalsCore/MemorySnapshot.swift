import Darwin
import Foundation

/// The kernel's memory pressure, the same signal Activity Monitor colors its graph with.
public enum MemoryPressure: Sendable, Equatable {
    case normal, warning, critical

    /// From `kern.memorystatus_vm_pressure_level`: 1 normal, 2 warning, 4 critical.
    init?(kernelLevel: Int32) {
        switch kernelLevel {
        case 1: self = .normal
        case 2: self = .warning
        case 4: self = .critical
        default: return nil
        }
    }

    /// From `kern.memorystatus_level`, the percentage of memory the kernel still considers free.
    init(freePercentage: Int32) {
        self = freePercentage < 10 ? .critical : (freePercentage < 25 ? .warning : .normal)
    }
}

/// One reading of the machine's memory, in bytes.
public struct MemorySnapshot: Sendable {
    public let total: UInt64
    /// Activity Monitor's "Memory Used": app memory plus wired and compressed memory.
    public let used: UInt64
    public let fileCache: UInt64
    public let compressed: UInt64
    public let swapUsed: UInt64
    public let swapTotal: UInt64
    public let pressure: MemoryPressure

    public var available: UInt64 { total > used ? total - used : 0 }

    public static func read() -> MemorySnapshot? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        var page: vm_size_t = 0
        host_page_size(mach_host_self(), &page)
        let pageSize = UInt64(page)
        var swap = xsw_usage()
        var swapSize = MemoryLayout<xsw_usage>.size
        sysctlbyname("vm.swapusage", &swap, &swapSize, nil, 0)

        return MemorySnapshot(
            total: ProcessInfo.processInfo.physicalMemory,
            used: usedBytes(
                internalPages: stats.internal_page_count, purgeablePages: stats.purgeable_count,
                wiredPages: stats.wire_count, compressorPages: stats.compressor_page_count, pageSize: pageSize
            ),
            fileCache: UInt64(stats.external_page_count) * pageSize,
            compressed: UInt64(stats.compressor_page_count) * pageSize,
            swapUsed: swap.xsu_used,
            swapTotal: swap.xsu_total,
            pressure: readPressure()
        )
    }

    static func usedBytes(internalPages: UInt32, purgeablePages: UInt32, wiredPages: UInt32, compressorPages: UInt32, pageSize: UInt64) -> UInt64 {
        let app = UInt64(internalPages > purgeablePages ? internalPages - purgeablePages : 0)
        return (app + UInt64(wiredPages) + UInt64(compressorPages)) * pageSize
    }

    private static func readPressure() -> MemoryPressure {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_vm_pressure_level", &value, &size, nil, 0) == 0,
           let pressure = MemoryPressure(kernelLevel: value) {
            return pressure
        }
        size = MemoryLayout<Int32>.size
        if sysctlbyname("kern.memorystatus_level", &value, &size, nil, 0) == 0 {
            return MemoryPressure(freePercentage: value)
        }
        return .normal
    }
}
