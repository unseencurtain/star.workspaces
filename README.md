# Monitor Workspaces

An [Omarchy](https://omarchy.org/) bar widget that shows each monitor's own
workspace slots. Perfect for multi-monitor setups: every bar shows its monitor's
slots instead of every workspace on every bar.

It replaces the stock `omarchy.workspaces` widget with a per-monitor version.
No patching of Omarchy system files is required — the widget reads its own
monitor name from the bar surface, so it survives `omarchy update` untouched.

## How it works

The widget reads `hyprctl workspacerules -j` and keeps the rules assigned to its
monitor. Each monitor therefore needs a contiguous range of global Hyprland
workspace IDs, created with `hl.workspace_rule(...)`:

```lua
local workspace_layout = {
  { monitor = "eDP-1", count = 6 },
  { monitor = "HDMI-A-1", count = 12 },
}

local next_workspace = 1
for _, entry in ipairs(workspace_layout) do
  for slot = 1, entry.count do
    hl.workspace_rule({
      workspace = tostring(next_workspace),
      monitor = entry.monitor,
      default = slot == 1,
      persistent = true,
    })
    next_workspace = next_workspace + 1
  end
end
```

Hyprland workspace IDs are global, so two monitors cannot both own workspace
`1`. With the table above the laptop owns `1–6` and the external owns `7–18`;
the widget labels them `1–6` and `1–12` on their respective bars. Add another
`{ monitor = "...", count = N }` row for a third or fourth monitor.

The tooltip on each button shows the real global Hyprland workspace ID. A full
Omarchy configuration, including monitor-local keybinds, is in
[omarchy-plugins/configs/workspaces](https://github.com/unseencurtain/omarchy-plugins/tree/main/configs/workspaces).

### Omarchy 4.5

Omarchy 4.5's `monitor-workspaces.lua` renumbers occupied workspaces into fixed
10-slot blocks on reload and monitor changes (workspace `4` becomes `14`). If
you define your own layout, disable its reconcile pass before
`config.reloaded` fires — for example in `~/.config/hypr/monitors.lua`:

```lua
if o.workspaces then
  o.workspaces.reconcile = function() end
end
```

## Installation

```bash
omarchy plugin add https://github.com/unseencurtain/star.workspaces.git --enable --yes
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
Workspaces carried onto a monitor from an unplugged display are kept after the
monitor's own slots and labelled with their real ID.

## Layout

```
star.workspaces/
├── manifest.json     # Omarchy plugin manifest
└── Workspaces.qml    # The bar widget (QML)
```

## Requirements

- Omarchy (Quickshell shell)
- Hyprland with workspace rules (`hl.workspace_rule`)
- Qt 6.4+ (for the `Screen` attached property)

## License

MIT
