import Testing
@testable import MacVitalsCore

struct CPUMeterTests {
    @Test func firstSampleHasNoBaseline() {
        var meter = CPUMeter()
        #expect(meter.record(CPUMeter.Ticks(busy: 100, total: 400)) == nil)
    }

    @Test func usageIsTheShareOfBusyTicksSinceTheLastSample() {
        var meter = CPUMeter()
        _ = meter.record(CPUMeter.Ticks(busy: 100, total: 400))
        #expect(meter.record(CPUMeter.Ticks(busy: 130, total: 500)) == 30)
    }

    @Test func noElapsedTicksGivesNoReading() {
        var meter = CPUMeter()
        _ = meter.record(CPUMeter.Ticks(busy: 100, total: 400))
        #expect(meter.record(CPUMeter.Ticks(busy: 100, total: 400)) == nil)
    }

    @Test func liveSampleIsWithinRange() {
        var meter = CPUMeter()
        _ = meter.sample()
        if let usage = meter.sample() {
            #expect((0...100).contains(usage))
        }
    }
}
