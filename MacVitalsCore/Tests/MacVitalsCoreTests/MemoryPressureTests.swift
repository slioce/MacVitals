import Testing
@testable import MacVitalsCore

struct MemoryPressureTests {
    @Test func kernelLevelsMapToTheThreeStates() {
        #expect(MemoryPressure(kernelLevel: 1) == .normal)
        #expect(MemoryPressure(kernelLevel: 2) == .warning)
        #expect(MemoryPressure(kernelLevel: 4) == .critical)
        #expect(MemoryPressure(kernelLevel: 0) == nil)
    }

    @Test func freePercentageFallbackUsesTheKernelThresholds() {
        #expect(MemoryPressure(freePercentage: 50) == .normal)
        #expect(MemoryPressure(freePercentage: 20) == .warning)
        #expect(MemoryPressure(freePercentage: 5) == .critical)
    }

    @Test func usedMemoryFollowsActivityMonitor() {
        // App memory (internal minus purgeable) + wired + compressed, in pages.
        let used = MemorySnapshot.usedBytes(internalPages: 1000, purgeablePages: 200, wiredPages: 300, compressorPages: 100, pageSize: 4096)
        #expect(used == 1200 * 4096)
    }

    @Test func purgeableLargerThanInternalDoesNotUnderflow() {
        let used = MemorySnapshot.usedBytes(internalPages: 10, purgeablePages: 50, wiredPages: 1, compressorPages: 0, pageSize: 4096)
        #expect(used == 4096)
    }

    @Test func liveSnapshotIsConsistent() throws {
        let memory = try #require(MemorySnapshot.read())
        #expect(memory.total > 0)
        #expect(memory.used <= memory.total)
        #expect(memory.available == memory.total - memory.used)
    }
}
