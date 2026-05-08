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

Flat, small, single-sitting comprehension. `[shipped]` = exists in repo. `[planned]` = referenced here but not yet built — add when needed, don't pre-create empty files.

```
Our-Weather/
├── project.yml                    # XcodeGen spec — source of truth for project structure  [shipped]
├── .gitignore                     # blocks .p8/.p12/cert files + generated .xcodeproj      [shipped]
├── CLAUDE.md                      # this file                                              [shipped]
├── Sources/
│   ├── App/
│   │   ├── OurWeatherApp.swift    # @main entry point                                      [shipped]
│   │   └── RootView.swift         # paged TabView of WeatherPageViews + locations sheet    [shipped]
│   ├── Views/
│   │   ├── TempView.swift         # Dual F/C renderer + Temperature enum (pure helpers)    [shipped]
│   │   ├── WeatherPageView.swift  # one location's weather screen (header + sections)      [shipped]
│   │   ├── HourlyStrip.swift      # next 24/30h, tap to toggle horizontal/vertical layout  [shipped]
│   │   ├── DailyList.swift        # 10-day forecast: range bars, precip %, today's dot     [shipped]
│   │   ├── ConditionCards.swift   # 2-col grid: Feels Like, UV, Humidity, Wind, Sunrise    [shipped]
│   │   ├── WeatherBackground.swift # condition + isDay → gradient colors                   [shipped]
│   │   ├── LocationsSheet.swift   # search (Open-Meteo geocoding) + saved-list management  [shipped]
│   │   └── Aesthetics.swift       # `.legibleText()` thin-outline shadow modifier          [shipped]
│   ├── Widget/
│   │   ├── WeatherWidgetBundle.swift # @main WidgetBundle                                  [shipped]
│   │   ├── WeatherWidget.swift    # StaticConfiguration + WeatherBackground container       [shipped]
│   │   ├── WeatherWidgetView.swift # small/medium + accessory sizes                        [shipped]
│   │   ├── WeatherProvider.swift  # TimelineProvider, 30-min refresh, cached CLLocation    [shipped]
│   │   └── WeatherEntry.swift     # TimelineEntry data shape                               [shipped]
│   ├── Services/
│   │   ├── WeatherClient.swift    # Open-Meteo forecast client                             [shipped]
│   │   ├── LocationService.swift  # CoreLocation wrapper + reverse geocoding               [shipped]
│   │   ├── LocationStore.swift    # @Observable saved-locations + UserDefaults persistence [shipped]
│   │   └── GeocodingClient.swift  # Open-Meteo geocoding (city search → coordinates)       [shipped]
│   └── Models/
│       ├── Forecast.swift         # domain types (NOT Codable) consumed by views           [shipped]
│       └── SavedLocation.swift    # Codable user-pinned location, persisted in UserDefaults [shipped]
├── Tests/
│   └── TemperatureTests.swift     # swift-testing tests for Temperature helpers            [shipped]
├── Resources/
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/    # single 1024x1024 universal icon (Xcode generates the   [shipped]
│                                  # 120/152/etc. variants from this at build time)
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
- **Open-Meteo uses TWO date formats in one response.** `current.time`, `hourly.time`, `daily.sunrise`, `daily.sunset` are datetime strings (`"2026-05-07T16:00"`). `daily.time` is date-only (`"2026-05-07"`). Parsing all of them with one `"yyyy-MM-dd'T'HH:mm"` formatter silently fails on `daily.time` and `compactMap` drops every daily entry, producing an empty 10-day forecast. `WeatherClient.swift` keeps two formatters (`openMeteoDateTime` and `openMeteoDate`) for this reason — don't consolidate.
- **All on-gradient text uses `.legibleText()`.** White text on the dynamic blue/indigo/etc. background washes out without a tiny outline. The modifier in `Sources/Views/Aesthetics.swift` adds a single soft black shadow (radius 1.0, no offset, 30% opacity) — reads as a thin halo rather than a drop shadow. Apply at the `Text` / `Label` level, not at container level (otherwise the card's background gets shadowed too). `TempView` applies it internally so every temperature display is automatically outlined.

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
5. Tag a release (`git tag v0.1.0 && git push --tags`) to trigger `release.yml` → fastlane uploads to TestFlight
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
- **App icon is one 1024x1024 PNG — no alpha channel.** TestFlight rejects any IPA without iPhone 120x120 + iPad 152x152 icons. Xcode 14+'s "All-Sized Image" feature generates every required device variant at build time from a single 1024x1024 universal icon, so `AppIcon.appiconset/Contents.json` only references one image (`Icon-1024.png`). To replace the icon, just overwrite that PNG; do not add per-size entries unless you have a reason. **The PNG must not have an alpha channel** — App Store Connect (altool) rejects it with "Invalid large app icon ... can't be transparent or contain an alpha channel." Strip alpha before committing: flatten onto a white background and save as RGB (color type 2), not RGBA (color type 6).
- **`TARGETED_DEVICE_FAMILY: "1,2"` (iPhone + iPad) requires explicit iPad orientation key.** When the app declares iPad support, App Store Connect mandates `UISupportedInterfaceOrientations` for iPad. XcodeGen exposes this as `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` in `project.yml`. Omitting it causes altool to reject the upload with "No orientations were specified ... To support iPad multitasking, specify all four orientations."
- **Pin Xcode 26 explicitly in both `build.yml` and `release.yml`.** `macos-latest` runners ship Xcode 26 but default to Xcode 16.4, which builds against the iOS 18.5 SDK. Add `sudo xcode-select -s /Applications/Xcode_26.3.app/Contents/Developer` as the first step in both workflows (after checkout, before XcodeGen). Without this in `build.yml`, the build job compiles with Swift from Xcode 16.4 — a different compiler than `release.yml` uses — causing Swift 6 strictness divergence where `build.yml` passes but `release.yml` fails (or vice versa). Keeping both pinned to the same Xcode means CI and release use identical toolchains. Update the path when a newer Xcode 26.x arrives on the runner image.
- **`TimelineProvider` completion closures must be `@Sendable` and captured explicitly.** Swift 6 strict concurrency treats a `Task` body as a `sending` closure. Declare both parameters as `@escaping @Sendable` (e.g. `completion: @escaping @Sendable (WeatherEntry) -> Void`) and capture with `[completion]` in the Task body. `@Sendable` makes the closure type itself `Sendable` so the capture crosses the domain boundary safely; `[completion]` copies the value into the Task. Without `@Sendable`, Xcode 16.4's Swift 6 compiler rejects the capture with "passing closure as a 'sending' parameter risks causing data races" even when `[completion]` is present. Applies to both `getSnapshot` and `getTimeline`.
- **Declare encryption-export status to skip the TestFlight compliance prompt.** Without this, every TestFlight upload sits in "Missing Compliance" until you manually answer the encryption question in App Store Connect. Setting `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO` in `project.yml` declares the app uses only standard system crypto (HTTPS via `URLSession` qualifies as exempt). Permanent — no per-build prompt.
- **Never include `NSExtension` in a WidgetKit extension's Info.plist.** App Store Connect rejects the IPA with "Invalid Info.plist Key. The key 'NSExtension' is not valid" (error 409). On modern Xcode / iOS 26 SDK the build system injects the extension point identifier automatically when it processes `@main WidgetBundle` — supplying it again in a hand-authored plist is both redundant and fatal to validation. The widget target must use `GENERATE_INFOPLIST_FILE: YES` + `INFOPLIST_KEY_*` settings in `project.yml` (same pattern as the host app target), with no `Info.plist` file in `Sources/Widget/`.

## Apple Developer setup (one-time)

Before the first TestFlight upload works, the following must be in place. Most of this is portal-side, not in the codebase.

### Portal actions
1. **Register App IDs** — Apple Developer portal → Identifiers → App IDs → +; create two explicit App IDs:
   - `com.ourweather.app` — the main app
   - `com.ourweather.app.WeatherWidget` — the widget extension (WidgetKit requires its own App ID, separate from the host app's). **`fastlane match` will fail with "Couldn't find bundle identifier 'com.ourweather.app.WeatherWidget'" if this is missing** — it cannot create a provisioning profile for an unregistered ID, even with `readonly: false`.
   No special capabilities on either for now (WeatherKit only when/if we migrate from Open-Meteo).
2. **Create app record in App Store Connect** — My Apps → +; pick `com.ourweather.app`. Without this, fastlane uploads fail with "no such app." The widget extension does **not** need its own App Store Connect record — only the main app does.
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
- Project compiles + tests pass via `build.yml` on GitHub Actions; signed Release uploads to TestFlight via `release.yml`
- **Multi-location** — paged TabView swipes between saved locations iOS-Weather-style; `LocationStore` persists the list to `UserDefaults` and remembers the selected location across launches
- **Search** — list button (top-right) opens `LocationsSheet`; type to search via Open-Meteo's free geocoding API; tap a result to add + jump to it; swipe to delete pinned locations (Current Location can't be deleted)
- **Device location** — `LocationService` (CoreLocation `liveUpdates` + `CLGeocoder` reverse geocoding) inserts a "Current Location" entry at top on first successful resolve and auto-selects it
- **Per-location forecast** — `WeatherPageView` fetches Open-Meteo data per location, renders header + hourly + 10-day + condition cards, all in dual F/C via `TempView`
- **Hourly strip** — next 24h horizontally by default; tap the card to expand into a vertical list (~30h). In both layouts, hours are grouped by day and each non-today day gets a `.white.opacity(0.20)` capsule pill above its hours (today is implicit, no pill). Header shows a chevron that flips when expanded; transition animates with `.easeInOut(0.25)`.
- **Daily list** — exactly 10 days with iOS-Weather-style range bars (positioned along the week's min/max axis, color-graded by temperature), precipitation chance ≥30%, and a white dot on today's row showing the current temp
- **Condition cards** — 2-column grid of Feels Like, UV Index, Humidity, Wind, Sunrise/Sunset
- **Dynamic background** — `WeatherBackground` picks gradient colors based on `WeatherCondition` + `isDay`
- **Lock-screen + home-screen widget** (`WeatherWidget` extension) — small/medium/accessoryRectangular/accessoryCircular/accessoryInline. Refreshes every 30 min via `TimelineProvider`. Uses the system's cached `CLLocationManager.location` (kept fresh by the main app's foreground use); falls back to Cupertino if no cache. Same `WeatherBackground` and `TempView` as the main app for visual consistency.
- **Thin text outline** for legibility — `.legibleText()` modifier (in `Aesthetics.swift`) wraps every white-on-gradient text with a 30%-opacity black halo. Applied automatically by `TempView`; applied explicitly in headers, hourly time labels, daily day names, condition card labels, and all widget views.

Remaining pieces:
1. **Live Activity / Dynamic Island** — `ActivityKit` framework, `NSSupportsLiveActivities = YES`, lives in the same `WeatherWidget` extension; live current temp pinned to lock screen and Dynamic Island
2. **App Group for widget data** — currently the widget reads `CLLocationManager.location` cached by the system, which works but isn't synced to the user's selected saved location in the app. App Group + shared UserDefaults would let the widget show whichever location the user picked in `LocationStore`. Adds portal capability work + match cert regeneration.
3. *(stretch)* Response cache (~10 min) so re-opening the app doesn't refetch immediately
4. *(stretch)* WeatherKit migration (better data; needs entitlement enabled on the App ID)
5. *(stretch)* Replace placeholder app icon with real artwork
