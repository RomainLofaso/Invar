# Invar

Invar is a macOS utility that applies **localized visual transformations** to selected screen regions.

It is designed as a lightweight, non-invasive overlay system that operates independently of applications and does not modify global display settings.

---

## Overview

Modern operating systems offer global display options (dark mode, color inversion, filters), but these approaches are often too coarse-grained for certain use cases.

Invar explores a different design space:

- visual adaptations are **scoped to a specific screen region**
- the rest of the system remains unchanged
- no application-level integration is required

The project focuses on **local constraints**, **explicit boundaries**, and **predictable behavior**.

---

## Current Capabilities

- Screenshot-style selection of a fixed screen region
- Real-time color inversion applied only inside that region
- Click-through overlay (no input interception)
- Menu bar application
- Multi-monitor support
- Target refresh rate: 60 FPS (with graceful degradation)

---

## Download & Install (Unsigned)

Unsigned builds are provided for convenience and are not notarized. macOS will show a warning on first launch.

1. Download `Invar-<version>-macos-unsigned.zip` from GitHub Releases.
2. Unzip and drag `Invar.app` to `/Applications`.
3. First launch: right-click `Invar.app` → Open → Open.
4. Or: System Settings → Privacy & Security → Open Anyway.

Invar does not record video and processes locally on your Mac.

To build unsigned artifacts locally:
```bash
Tools/AppRelease/release_unsigned.sh
```

---

## License

MIT License. See `LICENSE`.
