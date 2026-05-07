# Our-Weather

A native iOS clone of Apple's Weather app with one core differentiator: **temperatures always display in both Fahrenheit and Celsius simultaneously** (e.g. `57°F / 14°C`). No toggle, no setting — both, always. This is the product.

## Stack

- **Swift 6 + SwiftUI** — native iOS 26+, matches the visual language we're cloning
- **XcodeGen** — generates `.xcodeproj` from a plain-text `project.yml` so the project is editable from Windows without checking in binary Xcode files
- **GitHub Actions (macos-latest runners)** — cloud builds; no local Mac required
- **fastlane** — automates TestFlight uploads from CI
- **Open-Meteo API** — weather data, free, no API key (https://open-meteo.com)
- **TestFlight → App Store** — distribution via existing Apple Developer account

### Why this stack

The developer works on Windows without local Xcode, but holds an Apple Developer account and has prior experience using GitHub Actions to build iOS apps in CI. Native Swift/SwiftUI gives the highest fidelity to the iOS Weather app — fluid gradients, blur effects, native animations, lock-screen widgets, Live Activities — none of which a cross-platform framework reproduces cleanly. The GitHub Actions macOS runners (free for public repos, generous tier for private) handle the build step. XcodeGen avoids the usual nightmare of editing a binary `.xcodeproj` outside Xcode.

## Architecture

Flat, small, single-sitting comprehension.

```
Our-Weather/
├── project.yml                    # XcodeGen spec — source of truth for project structure
├── Sources/
│   ├── App/
│   │   ├── OurWeatherApp.swift    # @main entry point
│   │   └── RootView.swift         # Top-level navigation
│   ├── Views/
│   │   ├── TempView.swift         # Dual F/C renderer — SINGLE SOURCE OF TRUTH for the dual-unit rule
│   │   ├── HourlyStrip.swift      # Horizontal hourly forecast
│   │   ├── DailyList.swift        # 10-day forecast
│   │   └── ConditionCard.swift    # UV, humidity, wind, pressure
│   ├── Services/
│   │   ├── WeatherClient.swift    # Open-Meteo client
│   │   └── LocationService.swift  # CoreLocation wrapper
│   └── Models/
│       └── Forecast.swift         # Codable response types
├── Resources/
│   ├── Assets.xcassets
│   └── Info.plist
├── fastlane/
│   ├── Fastfile
│   └── Appfile
└── .github/workflows/
    ├── build.yml                  # PR + main builds (lint, test, build)
    └── release.yml                # TestFlight upload on tag push
```

No nested feature folders, no Coordinators, no VIPER, no Combine wrappers around everything. Standard SwiftUI + `@Observable` (Swift 5.9+) for state. Add structure when something concrete demands it, not before.

## Core UX rule: dual-unit display

**Every temperature in the UI shows both units.**

- Standard format: `57°F / 14°C`
- Compact (tight rows like the hourly strip): `57° / 14°`
- Never display a single unit. Never a toggle. If a screen shows one unit, it's a bug.

Implement once in `Views/TempView.swift`; use everywhere:

```swift
TempView(celsius: 14.2)               // → 57°F / 14°C
TempView(celsius: 14.2, compact: true) // → 57° / 14°
```

Open-Meteo returns Celsius. Convert to Fahrenheit at the render layer; never duplicate it in the model.

```swift
extension Double {
    var asFahrenheit: Int { Int((self * 9/5 + 32).rounded()) }
    var asCelsius: Int { Int(self.rounded()) }
}
```

## Data source: Open-Meteo

- Endpoint: `https://api.open-meteo.com/v1/forecast`
- No API key, no auth, no signup
- Request `temperature_unit=celsius`; derive Fahrenheit at render time
- Cache responses ~10 minutes — weather doesn't change faster, and being courteous to a free public API matters
- All response types as `Codable` structs in `Sources/Models/Forecast.swift`

**Future option:** WeatherKit (Apple's own weather API, free with the Developer account, 500K calls/month). Better data, native integration, but requires entitlement setup. Migrate behind the same `WeatherClient` interface when needed.

## Development workflow (Windows → iPhone, no Mac)

1. Edit Swift files in **VS Code** with the *Swift* extension (sourcekit-lsp gives autocomplete + errors)
2. Pure-logic code (formatters, models, parsing) can be unit-tested locally on Windows via Swift Package Manager: `swift test`
3. UI changes are written without local previews — push to a feature branch
4. **GitHub Actions** runs `build.yml` on macos-latest: regenerates `.xcodeproj` via XcodeGen, runs tests, builds the app
5. Tag a release (`git tag v0.1.0 && git push --tags`) to trigger `release.yml` → fastlane uploads to TestFlight
6. Test on physical iPhone via the **TestFlight** app

The dev loop is slower than local Xcode (push-and-wait instead of cmd-R), so favor:
- **Heavy unit tests on logic** so as much as possible is verified locally
- **Small, atomic commits** so when CI breaks, the cause is obvious
- **Concise SwiftUI** so visual surprises in CI builds are minimized

## CI/CD

### `.github/workflows/build.yml`
Runs on every push and PR. Steps:
1. Checkout
2. Install XcodeGen via Homebrew
3. `xcodegen generate`
4. `xcodebuild test -scheme OurWeather -destination 'platform=iOS Simulator,name=iPhone 15'`
5. `xcodebuild build` for archive smoke-test

### `.github/workflows/release.yml`
Runs on tag push (`v*.*.*`). Steps:
1. Same as build, then
2. `fastlane beta` — archives, signs, and uploads to TestFlight using `App Store Connect API key` stored in GitHub Secrets

GitHub Actions secrets needed:
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY` (the .p8 file, base64-encoded)
- `MATCH_PASSWORD` (if using fastlane match for cert sync)

## Coding conventions

- **Swift 6, SwiftUI, iOS 26+ minimum.** Targeting current Swift/iOS unlocks the full set of modern SwiftUI APIs (`@Observable`, `ContentUnavailableView`, latest scroll/animation primitives, current Liquid Glass material) without back-compat ceremony.
- **`@Observable` over `ObservableObject`.** Cleaner, no `@Published` boilerplate.
- **No premature abstraction.** Three similar SwiftUI blocks is fine; abstract on the fourth.
- **Comments only for non-obvious *why*.** No comments restating what code does.
- **No third-party UI libraries.** Stay in SwiftUI. Add a dependency only when a real need appears (the only baseline ones are XcodeGen and fastlane, both build-tools).
- **One concern per file.** If a `View` grows past ~150 lines, split.
- **Prefer `struct` over `class`.** Reach for class only when reference semantics or `ObservableObject`-era APIs require it.
- **Force-unwraps are bugs.** Use `guard let` / `if let` / `??`.

## Deployment

```
git tag v0.1.0
git push --tags
```

That triggers `release.yml`, which runs fastlane in CI to archive, sign, and upload to TestFlight. The Apple Developer account holds the app record; TestFlight handles internal/external testing distribution.

App Store release adds a metadata pass via fastlane `deliver` and a separate `release` lane.

## Alternatives considered

| Option | Why not |
|---|---|
| Expo / React Native | JS codebase can't match iOS Weather's native fidelity (animations, blur, widgets, Live Activities) |
| Native + cloud Mac (MacInCloud) | Better dev loop but adds recurring cost; CI-only is workable since user has prior experience with this pattern |
| Native + buy a Mac mini | Best dev experience long-term; reasonable upgrade if CI-only loop becomes painful |
| Capacitor / Cordova | Web-shell wrapper; same fidelity issues as RN, plus needs Xcode locally |

If the CI-only inner loop becomes a productivity bottleneck, the natural escalation is renting MacInCloud (~$30/mo) for real-time Xcode access — no code changes required.

## Getting started (clean slate)

Project is currently empty. First implementation steps:

1. **Author `project.yml`** — XcodeGen spec defining the iOS app target, deployment target (iOS 17), bundle ID, and source paths
2. **Author `Package.swift`** at the Sources/ logic-only subset so `swift test` works on Windows for unit-testable code
3. **Build `TempView` first** — every other view depends on it; getting the dual-unit rule right at the source means it can't drift
4. **Wire `WeatherClient`** with mock JSON fixtures so views can render without hitting the network during tests
5. **Add `.github/workflows/build.yml`** before adding screens — verify CI builds on the empty shell, then iterate

Don't bootstrap by trying to scaffold a full Xcode project from Windows. The XcodeGen-driven flow means committing `project.yml` and letting CI generate the `.xcodeproj` on every build.
