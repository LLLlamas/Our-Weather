import Testing
@testable import OurWeather

struct TempViewTests {
    @Test func freezingPointConvertsCorrectly() {
        let view = TempView(celsius: 0)
        #expect(view.fahrenheit == 32)
        #expect(view.celsiusInt == 0)
    }

    @Test func boilingPointConvertsCorrectly() {
        let view = TempView(celsius: 100)
        #expect(view.fahrenheit == 212)
        #expect(view.celsiusInt == 100)
    }

    @Test func roomTemperatureRoundsCorrectly() {
        let view = TempView(celsius: 21.6)
        #expect(view.fahrenheit == 71)
        #expect(view.celsiusInt == 22)
    }

    @Test func subZeroCelsiusConvertsCorrectly() {
        let view = TempView(celsius: -10)
        #expect(view.fahrenheit == 14)
        #expect(view.celsiusInt == -10)
    }
}
