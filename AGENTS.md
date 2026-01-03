# Repository Guidelines

## Project Structure & Module Organization
- `Invar/` contains the macOS app source code, grouped by feature (`App/`, `Capture/`, `Inversion/`, `Permissions/`, `Selection/`).
- `Invar/Assets.xcassets/` and `Assets.xcassets/` hold app assets and the AppIcon set.
- `Invar/Resources/` contains localized strings (`Localizable.strings`, `fr.lproj/`).
- `InvarTests/` and `InvarUITests/` hold unit and UI tests.
- `Tools/IconGenerator/` provides the Python-based app icon generator.
- `Invar.xcodeproj/` is the Xcode project and shared scheme definition.

## Build, Test, and Development Commands
- `open Invar.xcodeproj` opens the project in Xcode for local development.
- `xcodebuild -project Invar.xcodeproj -scheme Invar build` builds the app from the CLI.
- `xcodebuild -project Invar.xcodeproj -scheme Invar test -destination "platform=macOS"` runs unit and UI tests.
- If you hit DerivedData permission issues in a sandboxed environment, add `-derivedDataPath /tmp/InvarDerivedData`.
- `python3 -m venv Tools/IconGenerator/.venv && source Tools/IconGenerator/.venv/bin/activate && pip install -r Tools/IconGenerator/requirements.txt` sets up the icon generator.
- `swift Tools/IconGenerator/generate_icons.swift --output Tools/IconGenerator/build` generates app, permission, and status bar icons from the custom rounded-rect symbol.
- `swift Tools/IconGenerator/sync_icons.swift --source Tools/IconGenerator/build/app_icon --destination Invar/Assets.xcassets/AppIcon.appiconset` copies generated app icons into the Xcode asset catalog.
- `Tools/IconGenerator/build/permission_icon` and `Tools/IconGenerator/build/status_bar` should be copied to `PermissionIcon.imageset` and `StatusBarIcon.imageset`.

## Coding Style & Naming Conventions
- Use Xcode’s default Swift formatting with 4-space indentation.
- Follow Swift naming conventions: `UpperCamelCase` for types, `lowerCamelCase` for functions and variables.
- Keep files scoped to a single feature area (mirror the `Invar/` subfolders).

## Testing Guidelines
- Unit tests live in `InvarTests/`, UI tests in `InvarUITests/`.
- Use descriptive test names that read like behaviors (e.g., `testRegionSelectionKeepsOverlayVisible`).
- Run tests with the `xcodebuild ... test` command before opening a PR.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and title-cased (e.g., “Rename project to Invar and update assets”).
- PRs should include a brief summary, testing notes, and screenshots for UI changes.
- Link relevant issues or design notes when applicable.
- Keep `Invar.xcodeproj` in sync with added or deleted files so Xcode reflects the real repo state.

## Configuration & Permissions Notes
- The app requires macOS Screen Recording permission; changes impacting capture flow should be verified in System Settings.
