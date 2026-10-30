import Darwin

/// Resident memory of one app, summing every process that runs from its bundle.
public struct AppMemory: Sendable, Equatable {
    public let name: String
    public let residentBytes: UInt64
    public let processCount: Int
}

public enum ProcessMemory {
    /// The apps using the most resident memory among the current user's processes, largest first.
    /// Other users' processes are not visible to a sandboxed app, so they are left out.
    public static func topApps(_ limit: Int) -> [AppMemory] {
        var entries: [(name: String, bytes: UInt64)] = []
        var pathBuffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        var taskInfo = proc_taskinfo()
        let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)

        for pid in userProcessIDs() {
            guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize) == taskInfoSize,
                  taskInfo.pti_resident_size > 0
            else { continue }
            let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
            let name = pathLength > 0
                ? displayName(forPath: string(pathBuffer, length: pathLength))
                : processName(pid)
            entries.append((name, taskInfo.pti_resident_size))
        }
        return aggregate(entries, limit: limit)
    }

    /// Process IDs owned by the current user, from the kernel's process table.
    private static func userProcessIDs() -> [pid_t] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0 else { return [] }
        let stride = MemoryLayout<kinfo_proc>.stride
        var table = [kinfo_proc](repeating: kinfo_proc(), count: size / stride + 16)  // room for processes born meanwhile
        size = table.count * stride
        guard sysctl(&mib, 3, &table, &size, nil, 0) == 0 else { return [] }
        let uid = getuid()
        return table.prefix(size / stride)
            .filter { $0.kp_eproc.e_ucred.cr_uid == uid }
            .map(\.kp_proc.p_pid)
    }

    private static func processName(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        return length > 0 ? string(buffer, length: length) : "pid \(pid)"
    }

    private static func string(_ buffer: [CChar], length: Int32) -> String {
        String(decoding: buffer.prefix(Int(length)).map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    /// The outermost `.app` bundle on the path, so helpers count towards their app; otherwise the executable name.
    static func displayName(forPath path: String) -> String {
        let components = path.split(separator: "/")
        if let bundle = components.first(where: { $0.hasSuffix(".app") }) {
            return String(bundle.dropLast(4))
        }
        return components.last.map(String.init) ?? path
    }

    static func aggregate(_ entries: [(name: String, bytes: UInt64)], limit: Int) -> [AppMemory] {
        var byName: [String: (bytes: UInt64, count: Int)] = [:]
        for entry in entries {
            byName[entry.name, default: (0, 0)].bytes += entry.bytes
            byName[entry.name, default: (0, 0)].count += 1
        }
        return byName
            .map { AppMemory(name: $0.key, residentBytes: $0.value.bytes, processCount: $0.value.count) }
            .sorted { $0.residentBytes != $1.residentBytes ? $0.residentBytes > $1.residentBytes : $0.name < $1.name }
            .prefix(limit)
            .map { $0 }
    }
}
