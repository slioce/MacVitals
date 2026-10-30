import Testing
@testable import MacVitalsCore

struct ProcessMemoryTests {
    @Test func appHelpersTakeTheNameOfTheirBundle() {
        let helper = "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/1/Helpers/Google Chrome Helper (Renderer).app/Contents/MacOS/Google Chrome Helper (Renderer)"
        #expect(ProcessMemory.displayName(forPath: helper) == "Google Chrome")
        #expect(ProcessMemory.displayName(forPath: "/System/Applications/Mail.app/Contents/MacOS/Mail") == "Mail")
    }

    @Test func plainExecutablesKeepTheirFileName() {
        #expect(ProcessMemory.displayName(forPath: "/usr/libexec/trustd") == "trustd")
        #expect(ProcessMemory.displayName(forPath: "node") == "node")
    }

    @Test func processesAreSummedPerAppAndSortedByMemory() {
        let apps = ProcessMemory.aggregate([
            ("Mail", 300), ("Chrome", 500), ("Chrome", 400), ("node", 100), ("Mail", 100),
        ], limit: 2)
        #expect(apps.map(\.name) == ["Chrome", "Mail"])
        #expect(apps.map(\.residentBytes) == [900, 400])
        #expect(apps.map(\.processCount) == [2, 2])
    }

    @Test func liveReadingIncludesTheTestProcess() {
        let apps = ProcessMemory.topApps(1000)
        #expect(!apps.isEmpty)
        #expect(apps.allSatisfy { $0.residentBytes > 0 && $0.processCount > 0 })
    }
}
