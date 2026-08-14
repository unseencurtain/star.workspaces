import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
    id: root

    property string monitorName: Screen.name || ""

    function workspaceById(id) {
        var values = Hyprland.workspaces.values

        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i]
        }

        return null
    }

    property var workspaceList: {
        var result = []
        var values = Hyprland.workspaces.values
        var monitor = root.monitorName

        for (var i = 0; i < values.length; i++) {
            var ws = values[i]

            if (ws.id > 0 &&
                ws.monitor &&
                String(ws.monitor.name) === monitor) {
                result.push(ws.id)
            }
        }

        result.sort(function(a, b) {
            return a - b
        })

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
                required property int modelData

                readonly property var workspace:
                    root.workspaceById(modelData)

                readonly property bool occupied:
                    workspace !== null &&
                    workspace.toplevels.values.length > 0

                readonly property bool focused:
                    Hyprland.focusedWorkspace !== null &&
                    Hyprland.focusedWorkspace.id === modelData

                bar: root.bar

                text: focused
                    ? "\uDB85\uDCFB"
                    : String(modelData)

                opacity: occupied || focused ? 1 : 0.5

                horizontalMargin: 6
                verticalPadding: 6

                fixedWidth: root.vertical
                    ? root.barSize
                    : Style.space(20)

                fixedHeight: root.barSize

                onPressed: root.focusWorkspace(modelData)
            }
        }
    }
}
