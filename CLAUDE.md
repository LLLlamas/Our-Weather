# Our-Weather

A native iOS clone of Apple's Weather app with one core differentiator: **temperatures always display in both Fahrenheit and Celsius simultaneously** (e.g. `57°F / 14°C`). No toggle, no setting — both, always. This is the product.

## Stack

- **Swift 6 + SwiftUI** — native iOS 26+, matches the visual language we're cloning
- **XcodeGen** — generates `.xcodeproj` from a plain-text `project.yml` so the project is editable from Windows without checking in binary Xcode files
- **GitHub Actions (macos-latest runners)** — cloud builds; no local Mac required
- **fastlane** — automates TestFlight uploads from CI *(planned, not yet wired)*
- **Open-Meteo API** — weather data, free, no API key (https://open-meteo.com)
- **TestFlight → App Store** — distribution via existing Apple Developer account

### Why this stack

The developer works on Windows without local Xcode, but holds an Apple Developer account and has prior experience using GitHub Actions to build iOS apps in CI. Native Swift/SwiftUI gives the highest fidelity to the iOS Weather app — fluid gradients, blur effects, native animations, lock-screen widgets, Live Activities — none of which a cross-platform framework reproduces cleanly. The GitHub Actions macOS runners (free for public repos, generous tier for private) handle the build step. XcodeGen avoids the usual nightmare of editing a binary `.xcodeproj` outside Xcode.

## Architecture

Flat, small, single-sitting comprehension. `[shipped]` = exists in repo. `[planned]` = referenced here but not yet built — add when needed, don't pre-create empty files.

```
Our-Weather/
├── project.yml                    # XcodeGen spec — source of truth for project structure  [shipped]
├── .gitignore                     # blocks .p8/.p12/cert files + generated .xcodeproj      [shipped]
├── CLAUDE.md                      # this file                                              [shipped]
├── Sources/
│   ├── App/
│   │   ├── OurWeatherApp.swift    # @main entry point                                      [shipped]
│   │   └── RootView.swift         # current weather screen, async fetch + dual-unit row    [shipped]
│   ├── Views/
│   │   ├── TempView.swift         # Dual F/C renderer + Temperature enum (pure helpers)    [shipped]
│   │   ├── HourlyStrip.swift      # horizontal hourly forecast (next 24h)                  [shipped]
│   │   ├── DailyList.swift        # 10-day forecast list                                   [shipped]
│   │   ├── ConditionCards.swift   # 2-col grid: Feels Like, UV, Humidity, Wind, Sunrise    [shipped]
│   │   └── WeatherBackground.swift # condition + isDay → gradient colors                   [shipped]
│   ├── Services/
│   │   ├── WeatherClient.swift    # Open-Meteo client; private wire-format types inside    [shipped]
│   │   └── LocationService.swift  # CoreLocation wrapper + reverse geocoding               [shipped]
│   └── Models/
│       └── Forecast.swift         # domain types (NOT Codable) consumed by views           [shipped]
├── Tests/
│   └── TemperatureTests.swift     # swift-testing tests for Temperature helpers            [shipped]
├── Gemfile                                                                                [shipped]
├── fastlane/
│   ├── Fastfile                   # `beta` lane (build+sign+upload), `sync_certs` lane    [shipped]
│   ├── Appfile                    # bundle ID + team ID                                   [shipped]
│   └── Matchfile                  # match storage + cert type config                      [shipped]
└── .github/workflows/
    ├── build.yml                  # PR + main: xcodegen, build, test                      [shipped]
    └── release.yml                # TestFlight upload on tag push                         [shipped]
```

No nested feature folders, no Coordinators, no VIPER, no Combine wrappers around everything. Standard SwiftUI + `@Observable` for state. Add structure when something concrete demands it, not before.

## Core UX rule: dual-unit display

**Every temperature in the UI shows both units.**

- Standard format: `57°F / 14°C`
- Compact (tight rows like the hourly strip): `57° / 14°`
- Never display a single unit. Never a toggle. If a screen shows one unit, it's a bug.

Implement once in `Sources/Views/TempView.swift`; use everywhere:

```swift
TempView(celsius: 14.2)               // → 57°F / 14°C
TempView(celsius: 14.2, compact: true) // → 57° / 14°
```

Open-Meteo returns Celsius. Convert to Fahrenheit at the render layer; never duplicate it in the model. The conversion lives in a top-level `Temperature` enum (not on `View`, so it isn't `@MainActor`-bound and stays freely callable from tests):

```swift
enum Temperature {
    static func fahrenheit(fromCelsius celsius: Double) -> Int { ... }
    static func celsius(rounded celsius: Double) -> Int { ... }
}
```

## Data layer

- **Wire format types** (`OpenMeteoResponse` + nested `Current`/`Hourly`/`Daily`) are `private` inside `Sources/Services/WeatherClient.swift`. They mirror Open-Meteo's parallel-array shape and never leak out of that file.
- **Domain types** (`Forecast`, `CurrentConditions`, `HourlyEntry`, `DailyEntry`, `WeatherCondition`) live in `Sources/Models/Forecast.swift`. They are NOT `Codable` — they're the clean shape views consume. All `Sendable`.
- **WMO weather codes** are mapped to a small `WeatherCondition` enum in `Forecast.swift`. Add codes if Open-Meteo returns one we miss.

## Data source: Open-Meteo

- Endpoint: `https://api.open-meteo.com/v1/forecast`
- No API key, no auth, no signup
- Request `temperature_unit=celsius`; derive Fahrenheit at render time
- Cache responses ~10 minutes — weather doesn't change faster, and being courteous to a free public API matters *(caching not yet implemented)*

**Future option:** WeatherKit (Apple's own weather API, free with the Developer account, 500K calls/month). Better data, native integration, but requires entitlement setup. Migrate behind the same `WeatherClient` protocol when needed.

## Development workflow (Windows → iPhone, no Mac)

1. Edit Swift files in **VS Code** with the *Swift* extension (sourcekit-lsp gives autocomplete + errors)
2. Pure-logic code (formatters, models, parsing) can be unit-tested locally on Windows via Swift Package Manager: `swift test` *(no `Package.swift` yet — add when needed)*
3. UI changes are written without local previews — push to a feature branch
4. **GitHub Actions** runs `build.yml` on macos-latest: regenerates `.xcodeproj` via XcodeGen, builds the app, runs tests
5. Tag a release (`git tag v0.1.0 && git push --tags`) to trigger `release.yml` → fastlane uploads to TestFlight *(release.yml planned)*
6. Test on physical iPhone via the **TestFlight** app

The dev loop is slower than local Xcode (push-and-wait instead of cmd-R), so favor:
- **Heavy unit tests on logic** so as much as possible is verified locally
- **Small, atomic commits** so when CI breaks, the cause is obvious
- **Concise SwiftUI** so visual surprises in CI builds are minimized

## CI/CD

### `.github/workflows/build.yml` *(shipped)*
Runs on every push and PR. Steps:
1. Checkout
2. List installed Xcode versions (debug aid for SDK availability)
3. Install XcodeGen via Homebrew
4. `xcodegen generate`
5. `xcodebuild build` against `generic/platform=iOS Simulator` with `CODE_SIGNING_ALLOWED=NO`
6. `xcodebuild test` against `iPhone 16` simulator with `OS=latest`

No signing in this workflow — it only verifies the project compiles and tests pass.

### `.github/workflows/release.yml` *(shipped)*
Runs on tag push (`v*.*.*`) or manual dispatch. Steps:
1. Checkout
2. Setup Ruby 3.3 with bundler cache (installs `fastlane` from `Gemfile`)
3. Install XcodeGen via Homebrew
4. `xcodegen generate`
5. `bundle exec fastlane beta`:
   - `setup_ci` — creates a temporary keychain so signing doesn't fight a (nonexistent) login keychain
   - `match(type: "appstore", readonly: false)` — first run generates the distribution cert + provisioning profile via the App Store Connect API key, encrypts with `MATCH_PASSWORD`, and pushes to the match repo. Subsequent runs decrypt and reuse.
   - `build_app` — Release archive, app-store export, build number from `GITHUB_RUN_NUMBER`
   - `upload_to_testflight` — pushes to App Store Connect; available in TestFlight on your iPhone within ~5–15 min after Apple processes the build

The build number passed via `xcargs: CURRENT_PROJECT_VERSION=…` rather than mutating the project file (XcodeGen would clobber any in-place change on the next regeneration).

## Coding conventions

- **Swift 6, SwiftUI, iOS 26+ minimum.** Targeting current Swift/iOS unlocks the full set of modern SwiftUI APIs (`@Observable`, `ContentUnavailableView`, latest scroll/animation primitives, current Liquid Glass material) without back-compat ceremony.
- **`@Observable` over `ObservableObject`.** Cleaner, no `@Published` boilerplate.
- **Pure helpers stay outside `View`.** SwiftUI's `View` is `@MainActor`-isolated under Swift 6 strict concurrency, so any computed property defined on a `View`-conforming struct inherits MainActor isolation and can't be called from synchronous tests. Put pure logic (conversions, parsing) in top-level enums/functions instead — see `Temperature` in `TempView.swift`.
- **No premature abstraction.** Three similar SwiftUI blocks is fine; abstract on the fourth.
- **Comments only for non-obvious *why*.** No comments restating what code does.
- **No third-party UI libraries.** Stay in SwiftUI. Add a dependency only when a real need appears (the only baseline ones are XcodeGen and fastlane, both build-tools).
- **One concern per file.** If a `View` grows past ~150 lines, split.
- **Prefer `struct` over `class`.** Reach for class only when reference semantics are required.
- **Force-unwraps are bugs.** Use `guard let` / `if let` / `??`.
- **Never set `PRODUCT_NAME`** in `project.yml` to a value that differs from the target name — Xcode derives `TEST_HOST` from the target name, so a custom `PRODUCT_NAME` breaks unit-test linkage. Use `INFOPLIST_KEY_CFBundleDisplayName` for the home-screen label instead.
- **Release config uses Manual signing with the match profile name.** `Automatic` signing won't find match-installed profiles and `xcodebuild archive` fails with "No profiles for ... were found." `project.yml` sets `CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: Apple Distribution`, and `PROVISIONING_PROFILE_SPECIFIER: match AppStore com.ourweather.app` for the Release config only. Debug stays Automatic (irrelevant since we never build Debug for distribution).

## Apple Developer setup (one-time)

Before the first TestFlight upload works, the following must be in place. Most of this is portal-side, not in the codebase.

### Portal actions
1. **Register App ID** — Apple Developer portal → Identifiers → App IDs → explicit, bundle ID `com.ourweather.app` (must match `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml`). No special capabilities yet (WeatherKit only when/if we migrate from Open-Meteo).
2. **Create app record in App Store Connect** — My Apps → +; pick the registered bundle ID. Without this, fastlane uploads fail with "no such app."
3. **Find Team ID** — Membership page; populate `DEVELOPMENT_TEAM` in `project.yml`. *(currently `GYFN949Q5E`)*
4. **Create App Store Connect API Key** — Users and Access → Integrations → App Store Connect API → +; role **App Manager**. Download the `.p8` once. Note the **Key ID** and **Issuer ID**.

### Code signing — `fastlane match` *(shipped)*
Stores the distribution certificate + provisioning profile encrypted in a private git repo; CI pulls them on every build. The first run of `release.yml` generates the cert via the App Store Connect API key, encrypts with `MATCH_PASSWORD`, and pushes to the match repo. No extra Apple Developer portal action needed — match provisions certs through the API key.

**One-time bootstrap (do these once, in order, before pushing the first tag):**
1. **Create a private GitHub repo for the certs** — name it whatever you want (e.g. `Our-Weather-certs`). It can stay empty; match will populate it on first run.
2. **Generate a fine-grained personal access token (PAT)** — GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens. Repository access: only the certs repo. Permissions: **Contents: Read and write**.
3. **Add two new GitHub Actions secrets** (Repo → Settings → Secrets and variables → Actions):
   - `MATCH_GIT_URL` — embed the PAT in the URL: `https://x-access-token:YOUR_PAT@github.com/LLLlamas/Our-Weather-certs.git`. This is simpler and more reliable than the alternative basic-auth-header approach (which requires base64-encoding the PAT and is sensitive to whitespace in the secret editor).
   - `MATCH_PASSWORD` — pick a strong passphrase, save it in your password manager. Lose this and the certs in the match repo become unrecoverable (revoke + regenerate from scratch).
4. **Test locally first** — before triggering the workflow, verify auth works from your machine:
   ```powershell
   git ls-remote https://x-access-token:YOUR_PAT@github.com/LLLlamas/Our-Weather-certs.git
   ```
   Empty output (or HEAD/branch refs) = success. Authentication failed = wrong PAT or scope. Repository not found = wrong URL.
5. **Confirm App Store Connect app record exists** — `My Apps → +` with bundle ID `com.ourweather.app`. Without it, `upload_to_testflight` fails.
6. **Trigger the workflow** — first time, do it manually via Actions → Release to TestFlight → Run workflow (avoids burning a tag if anything fails). Once green, subsequent releases via `git tag v0.1.0 && git push --tags`. First run takes ~10–15 min (cert generation + initial archive). Subsequent runs are faster (~5–8 min).

### GitHub Actions secrets

| Secret | Source | Status |
|---|---|---|
| `APPLE_TEAM_ID` | Membership page | set by user |
| `APP_STORE_CONNECT_API_KEY_ID` | API key page | set by user |
| `APP_STORE_CONNECT_API_ISSUER_ID` | API key page | set by user |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | `AuthKey_XXX.p8` base64-encoded. PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXX.p8")) \| Set-Clipboard`. CI decodes this to `$RUNNER_TEMP/private_keys/AuthKey.p8` and fastlane reads the file via `key_filepath` — avoids Ruby string parsing of the key content (which has historically failed with "null byte" or "invalid curve name" when secrets get whitespace-mangled by browser editors). | set by user |
| `MATCH_PASSWORD` | Passphrase you choose; encrypts certs in the match repo | set by user |
| `MATCH_GIT_URL` | Private cert repo URL with PAT embedded: `https://x-access-token:PAT@github.com/LLLlamas/Our-Weather-certs.git` | set by user |

### What NOT to do yet
- Don't enable WeatherKit — we're on Open-Meteo. Defer until/unless we migrate.
- Don't fill App Store metadata / screenshots — TestFlight builds work without it; only required for App Store release.
- Don't manually create distribution certificates or provisioning profiles — `match` does it.
- Don't register devices — TestFlight doesn't need UDIDs (that's only for ad-hoc / development builds).

### Secret hygiene
- `.p8` keys, `.p12` certs, `.mobileprovision` files, and `.env` files are in `.gitignore`. Never commit them.
- The `.p8` is single-download; if lost, revoke the key and generate a new one.

## Deployment

```
git tag v0.1.0
git push --tags
```

Will trigger `release.yml` once that workflow lands, which runs fastlane in CI to archive, sign, and upload to TestFlight. The Apple Developer account holds the app record; TestFlight handles internal/external testing distribution.

App Store release adds a metadata pass via fastlane `deliver` and a separate `release` lane.

## Alternatives considered

| Option | Why not |
|---|---|
| Expo / React Native | JS codebase can't match iOS Weather's native fidelity (animations, blur, widgets, Live Activities) |
| Native + cloud Mac (MacInCloud) | Better dev loop but adds recurring cost; CI-only is workable since user has prior experience with this pattern |
| Native + buy a Mac mini | Best dev experience long-term; reasonable upgrade if CI-only loop becomes painful |
| Capacitor / Cordova | Web-shell wrapper; same fidelity issues as RN, plus needs Xcode locally |

If the CI-only inner loop becomes a productivity bottleneck, the natural escalation is renting MacInCloud (~$30/mo) for real-time Xcode access — no code changes required.

## Documentation hygiene

**CLAUDE.md is a living document and must be kept in sync with reality.** When making changes that affect any of the following, update CLAUDE.md in the same change set — not as a follow-up:

- File or folder structure (add/remove/move/rename) → update the architecture diagram and shipped/planned markers
- Stack choices, dependencies, deployment target → update the Stack section
- Coding conventions or product rules → update the relevant section
- CI/CD workflow steps, secrets, or destinations → update CI/CD + Apple Developer setup
- A "planned" item that ships → flip its marker to `[shipped]` and refresh any prose that referenced it as future work

If a change makes a section of CLAUDE.md inaccurate, fix the section. If the section is no longer needed, delete it. The cost of an out-of-date doc is much higher than the cost of editing it.

## Current status & next steps

What's working today:
- Project compiles + tests pass via `build.yml` on GitHub Actions
- App fetches real Open-Meteo data and renders current temp + condition + today's H/L, all in dual F/C via `TempView`
- **Device location** via `LocationService` (CoreLocation `liveUpdates` + `CLGeocoder` reverse geocoding); falls back to Cupertino if permission is denied/unavailable
- **Hourly strip** — horizontal scroll of next 24h with weather icon + compact dual-unit temp
- **Daily list** — 10-day forecast with day name, condition icon, dual-unit low/high
- **Condition cards** — 2-column grid of Feels Like, UV Index, Humidity, Wind, Sunrise/Sunset
- **Dynamic background** — `WeatherBackground` picks gradient colors based on `WeatherCondition` + `isDay` (clear/partly cloudy have day vs night variants; rain/snow/storm are same day or night)

Remaining pieces (after first TestFlight build lands):
1. *(stretch)* Response cache (~10 min) so screen-on doesn't refetch every time
2. *(stretch)* Live Activity / lock-screen widget showing current temp in dual F/C
3. *(stretch)* WeatherKit migration (better data; needs entitlement enabled on the App ID)
4. *(stretch)* Search / saved-locations list so you can check weather for places other than current location
