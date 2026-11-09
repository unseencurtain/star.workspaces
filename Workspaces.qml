import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
    id: root

    property string monitorName: Screen.name || ""

    // Sizes live in ~/.config/omarchy/bar-sizes.json (section "workspaces"),
    // with the shell.json widget setting and then the theme as fallbacks.
    property var sizeConfig: ({})
    readonly property var wsSizes: root.sizeConfig.workspaces || ({})

    readonly property int numberSize: {
        var v = Number(wsSizes.numberSize)
        if (isFinite(v) && v > 0) return Math.round(v)
        var s = Number(setting("fontSize", 0))
        return (isFinite(s) && s > 0) ? s : Style.font.body
    }

    readonly property int glyphSize: {
        var v = Number(wsSizes.glyphSize)
        if (isFinite(v) && v > 0) return Math.round(v)
        return root.numberSize
    }

    readonly property string glyph:
        (wsSizes.glyph !== undefined && wsSizes.glyph !== null)
            ? String(wsSizes.glyph)
            : "\uDB85\uDCFB"

    // Workspace IDs that Hyprland assigns to this monitor through workspace
    // rules. The widget reads `hyprctl workspacerules -j`, so the Lua config is
    // the only source of truth: changing a monitor's count or range there
    // updates the bar without a second config file.
    property var slotIds: []
    property bool slotsStale: false

    function workspaceById(id) {
        var values = Hyprland.workspaces.values

        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i]
        }

        return null
    }

    function refreshSlots() {
        if (!root.monitorName)
            return

        if (rulesProc.running) {
            root.slotsStale = true
            return
        }

        root.slotsStale = false
        rulesProc.running = true
    }

    function readSlots(text) {
        var ids = []

        try {
            var rules = JSON.parse(text)

            for (var i = 0; i < rules.length; i++) {
                var rule = rules[i]

                if (!rule || rule.enabled === false)
                    continue

                if (String(rule.monitor || "") !== root.monitorName)
                    continue

                var id = parseInt(String(rule.workspaceString || ""), 10)
                if (!isFinite(id) || id <= 0)
                    continue

                ids.push(id)
            }
        } catch (e) {
            ids = []
        }

        ids.sort(function(a, b) {
            return a - b
        })

        var unique = []
        for (var j = 0; j < ids.length; j++) {
            if (j === 0 || ids[j] !== ids[j - 1])
                unique.push(ids[j])
        }

        root.slotIds = unique
    }

    // Each monitor's own slots, labelled 1..N. A workspace physically on this
    // monitor but not in its rule set (for example one carried over from an
    // unplugged monitor) is kept after them and labelled with its real ID.
    property var workspaceList: {
        var result = []
        var values = Hyprland.workspaces.values
        var ids = root.slotIds

        if (ids.length === 0) {
            // Rules have not loaded yet, or this monitor has none: fall back
            // to whatever Hyprland currently has on it.
            var fallback = []

            for (var i = 0; i < values.length; i++) {
                var ws = values[i]

                if (ws.id > 0 &&
                    ws.monitor &&
                    String(ws.monitor.name) === root.monitorName)
                    fallback.push(ws.id)
            }

            fallback.sort(function(a, b) {
                return a - b
            })
            ids = fallback
        }

        var own = {}
        for (var j = 0; j < ids.length; j++) {
            own[ids[j]] = true
            result.push({ id: ids[j], label: j + 1, guest: false })
        }

        var guests = []
        for (var k = 0; k < values.length; k++) {
            var value = values[k]

            if (value.id > 0 &&
                value.monitor &&
                String(value.monitor.name) === root.monitorName &&
                !own[value.id])
                guests.push(value.id)
        }

        guests.sort(function(a, b) {
            return a - b
        })

        for (var g = 0; g < guests.length; g++)
            result.push({ id: guests[g], label: guests[g], guest: true })

        return result
    }

    function focusWorkspace(id) {
        if (!root.bar)
            return

        root.bar.run(
            "hyprctl dispatch " +
            Util.shellQuote(
                "hl.dsp.focus({ workspace = \"" + id + "\" })"
            )
        )
    }

    implicitWidth: root.workspaceList.length > 0
        ? grid.implicitWidth
        : 1

    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        anchors.fill: parent

        columns: root.vertical ? 1 : Math.max(1, root.workspaceList.length)
        columnSpacing: root.vertical ? 0 : Style.space(1)

        Repeater {
            model: root.workspaceList

            delegate: WidgetButton {
                required property var modelData

                readonly property var workspace:
                    root.workspaceById(modelData.id)

                readonly property bool occupied:
                    workspace !== null &&
                    workspace.toplevels.values.length > 0

                readonly property bool focused:
                    Hyprland.focusedWorkspace !== null &&
                    Hyprland.focusedWorkspace.id === modelData.id

                bar: root.bar

                text: focused && root.glyph !== ""
                    ? root.glyph
                    : String(modelData.label)

                tooltipText: modelData.guest
                    ? "Workspace " + modelData.id
                    : "Workspace " + modelData.id +
                      " (slot " + modelData.label + ")"

                opacity: occupied || focused
                    ? 1
                    : (modelData.guest ? 0.35 : 0.5)

                horizontalMargin: 6
                verticalPadding: 6
                fontSize: focused ? root.glyphSize : root.numberSize

                fixedWidth: root.vertical
                    ? root.barSize
                    : Style.space(20)

                fixedHeight: root.barSize

                onPressed: root.focusWorkspace(modelData.id)
            }
        }
    }

    Component.onCompleted: root.refreshSlots()
    onMonitorNameChanged: root.refreshSlots()

    // A config reload can change the workspace rules, and a monitor change can
    // move workspaces between bars. Re-read the rules for both.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            var name = event ? String(event.name) : ""

            if (name === "configreloaded" ||
                name === "monitoradded" ||
                name === "monitorremoved")
                root.refreshSlots()
        }
    }

    Process {
        id: rulesProc

        command: ["hyprctl", "workspacerules", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.readSlots(text)
        }

        onRunningChanged: {
            if (!running && root.slotsStale)
                root.refreshSlots()
        }
    }

    // One place to tweak sizes: ~/.config/omarchy/bar-sizes.json
    FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/bar-sizes.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var parsed = JSON.parse(text())
                root.sizeConfig = (parsed && typeof parsed === "object") ? parsed : ({})
            } catch (e) {
                root.sizeConfig = ({})
            }
        }
        onLoadFailed: root.sizeConfig = ({})
    }
}
