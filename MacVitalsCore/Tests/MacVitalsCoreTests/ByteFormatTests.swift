import Testing
@testable import MacVitalsCore

struct ByteFormatTests {
    @Test func compactUsesOneDecimalGigabyteAboveOneGigabyte() {
        #expect(ByteFormat.compact(5_583_457_484) == "5.2G")
        #expect(ByteFormat.compact(1 << 30) == "1.0G")
    }

    @Test func compactUsesWholeMegabytesBelowOneGigabyte() {
        #expect(ByteFormat.compact(512 << 20) == "512M")
        #expect(ByteFormat.compact(0) == "0M")
    }

    @Test func diskDropsDecimalsAboveOneHundredGigabytes() {
        #expect(ByteFormat.disk(408_790_000_000) == "409 GB")
        #expect(ByteFormat.disk(494_000_000_000) == "494 GB")
    }

    @Test func percentageIsRoundedToWholeNumbers() {
        #expect(ByteFormat.percentage(23.4) == "23%")
        #expect(ByteFormat.percentage(99.6) == "100%")
    }
}
