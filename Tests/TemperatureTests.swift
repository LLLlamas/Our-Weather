import Testing
@testable import OurWeather

struct TemperatureTests {
    @Test func freezingPoint() {
        #expect(Temperature.fahrenheit(fromCelsius: 0) == 32)
        #expect(Temperature.celsius(rounded: 0) == 0)
    }

    @Test func boilingPoint() {
        #expect(Temperature.fahrenheit(fromCelsius: 100) == 212)
        #expect(Temperature.celsius(rounded: 100) == 100)
    }

    @Test func roomTemperatureRounds() {
        #expect(Temperature.fahrenheit(fromCelsius: 21.6) == 71)
        #expect(Temperature.celsius(rounded: 21.6) == 22)
    }

    @Test func subZero() {
        #expect(Temperature.fahrenheit(fromCelsius: -10) == 14)
        #expect(Temperature.celsius(rounded: -10) == -10)
    }
}
