# Monitor Workspaces

An [Omarchy](https://omarchy.org/) bar widget that shows only the Hyprland
workspaces belonging to the monitor the bar is on. Perfect for multi-monitor
setups: each screen shows its own workspace buttons instead of every
workspace on every bar.

It replaces the stock `omarchy.workspaces` widget with a per-monitor version.
No patching of Omarchy system files is required — the widget reads its own
monitor name from the bar surface, so it survives `omarchy update` untouched.

## Installation

```bash
omarchy plugin add https://github.com/<user>/<repo>.git --enable --yes
omarchy bar move star.workspaces --section left
```

Or install by hand:

1. Copy this directory to `~/.config/omarchy/plugins/star.workspaces/`
2. `omarchy-shell shell rescanPlugins`
3. Add `{ "id": "star.workspaces" }` to the `bar.layout.left` array in
   `~/.config/omarchy/shell.json`

## Usage

The widget sits in the left section of the bar, one instance per monitor.
Click a workspace number to focus it. Occupied workspaces are shown at full
opacity; empty ones are dimmed. The focused workspace shows the active icon.

## Layout

```
star.workspaces/
├── manifest.json     # Omarchy plugin manifest
└── Workspaces.qml    # The bar widget (QML)
```

## Requirements

- Omarchy (Quickshell shell)
- Qt 6.4+ (for the `Screen` attached property)

## License

MIT
