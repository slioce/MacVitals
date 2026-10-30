# MacVitals

A menu bar app for macOS that keeps an eye on memory. A colored dot shows the system's memory pressure, next to how much memory is in use and how much has gone to swap. Click it for the details: memory, CPU, disk and the apps using the most memory.

```
●  5.2G  ⇅1.9G
```

## Features

- **Memory pressure at a glance**: the dot is green, yellow or red, following the same signal Activity Monitor uses for its memory graph.
- **Memory used**, counted the way Activity Monitor does: app memory plus wired and compressed memory.
- **Swap** appears in the menu bar only when the system is actually swapping, so a quiet Mac shows just the dot and the memory figure.
- **Menu with the details**: used, available, file cache, compressed, swap and pressure; CPU usage and load average; disk used and free; the five apps using the most resident memory, with their helper processes summed under the app's name.
- **Choose what sits in the menu bar**: memory, swap, CPU, any combination; refresh every 2, 5 or 10 seconds; launch at login.
- Localized in English and Italian.
- Sandboxed, under 1 MB on disk, no network access, and light enough to leave running on an 8 GB Mac.

## Requirements

macOS 15 or later, on Apple Silicon or Intel.

## Usage

MacVitals lives in the menu bar; it has no Dock icon and no windows.

- **Dot**: green means normal, yellow means the system is under memory pressure and has started compressing and swapping, red means it is critical and apps will slow down or be terminated.
- **Figure**: memory in use, in gigabytes.
- **⇅ figure**: swap in use, shown only above 64 MB.
- **Percentage**: CPU usage, if you turned it on.

Open the menu to read the full numbers. The list "Memory by app" covers your own processes; macOS does not let a sandboxed app inspect processes that belong to other users or to the system. "Open Activity Monitor" is right there when you need the whole picture.

## Settings

Everything is in the menu under **Settings**:

- **Show in Menu Bar**: Memory, Swap, CPU. Turn them all off to keep just the dot.
- **Refresh Every**: 2, 5 or 10 seconds. The default is 5.
- **Launch at Login**.

## Build from source

Requires Xcode 16 or later.

```sh
git clone https://github.com/slioce/MacVitals.git
cd MacVitals
make install   # builds, copies to /Applications and launches
make run       # launches the build without installing it
make test      # runs the tests of the readings
```

Or open `MacVitals.xcodeproj` in Xcode and press Run. The project is signed to run locally out of the box; no developer account is needed. Launch at Login only works for a copy in a stable location such as `/Applications`, so test it after `make install`.

## Project layout

```
MacVitals/              The app: menu bar item, menu, settings, timer. AppKit only, no SwiftUI.
MacVitals/Resources/    Info.plist, entitlements, privacy manifest, icon, localizations.
MacVitalsCore/          Swift package with the system readings and their tests. No AppKit, no UI.
Config/              Build settings shared by every configuration (xcconfig).
scripts/             make-icon.swift draws the app icon set.
```

The readings come from public system APIs, with nothing spawned and nothing privileged: `host_statistics64` for memory, `sysctl` for swap and memory pressure, `host_statistics` for CPU ticks, `URLResourceValues` for disk capacity, and `sysctl` plus `proc_pidinfo` for the memory of your processes. The menu is rebuilt only while it is opening, so the process scan runs on demand and the app stays idle between refreshes of the menu bar title.

## Publishing to the App Store

1. Create `Config/Local.xcconfig` (ignored by git) with your team:

   ```
   DEVELOPMENT_TEAM = ABCDE12345
   CODE_SIGN_IDENTITY = Apple Development
   ```

2. In Xcode, choose Product › Archive (or run `make archive`), then Distribute App › App Store Connect.

The app runs in the App Sandbox with no additional entitlements. The privacy manifest declares the two required-reason APIs it uses: user defaults, for its own settings, and disk space, to display free space to the user.

## Privacy

Everything happens on your Mac. MacVitals has no network access, collects no data, and keeps nothing but its settings. The privacy manifest (`PrivacyInfo.xcprivacy`) declares no tracking and no collected data.

## Acknowledgements

MacVitals was written with the help of AI coding agents; design, review and testing are the author's.

## License

Copyright © 2026 Alessandro Lioce. MacVitals is free software, released under the [GNU General Public License v3.0](LICENSE) or any later version.
