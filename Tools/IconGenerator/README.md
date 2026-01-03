# Icon Generator

Generates all macOS AppIcon PNG sizes from a custom rounded-rect “localized region” symbol.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Usage

```bash
swift generate_icons.swift \
  --output build
```

Then copy them into the Xcode asset catalog:

```bash
swift sync_icons.swift \
  --source build \
  --destination ../../Invar/Assets.xcassets/AppIcon.appiconset \
  --statusbar-destination ../../Invar/Assets.xcassets/StatusBarIcon.imageset \
  --permission-destination ../../Invar/Assets.xcassets/PermissionIcon.imageset
```

Generated outputs:
- `build/app_icon/` → AppIcon.appiconset
- `build/menubar/` → menu bar glyphs (optional)
- `build/panel/` → panel glyphs (light/dark)
- `build/permission_icon/` → `PermissionIcon.imageset`
- `build/status_bar/` → `StatusBarIcon.imageset`

The symbol is rendered as monochrome shapes with no gradients or text.

Optional tuning:

```bash
python generate_icons.py \
  --source /path/to/source.png \
  --output ../../Invar/Assets.xcassets/AppIcon.appiconset \
  --color #FFCC00 \
  --outer-width-pct 0.035 \
  --outer-radius-pct 0.18 \
  --inner-width-pct 0.025 \
  --inner-inset-pct 0.22
```
