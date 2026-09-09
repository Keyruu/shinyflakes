import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // Disable click-to-open; popout opens via DankBar's global hover handler
    // (requires services.dms.bar.hoverPopouts = true in dms.nix).
    pillClickAction: () => {}

    property string eventText: "No events"
    property string agendaText: ""
    property var agendaLines: []
    readonly property string displayText: {
        const max = 60;
        return eventText.length > max ? eventText.substring(0, max - 1) + "…" : eventText;
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            eventProcess.running = true
            agendaProcess.running = true
        }
    }

    Process {
        id: eventProcess
        command: ["next-event"]

        stdout: SplitParser {
            onRead: line => {
                if (line.trim().length > 0)
                    root.eventText = line.trim()
            }
        }
    }

    Process {
        id: agendaProcess
        command: ["next-events"]

        property var lines: []

        stdout: SplitParser {
            onRead: line => {
                agendaProcess.lines.push(line)
            }
        }

        onExited: {
            root.agendaLines = lines.length > 0 ? lines : ["No upcoming events"]
            lines = []
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingS

            DankIcon {
                name: "calendar_today"
                size: root.iconSize
                color: Theme.widgetIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.displayText
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "calendar_today"
                size: root.iconSize
                color: Theme.widgetIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Upcoming Events"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                Repeater {
                    model: root.agendaLines

                    Column {
                        width: parent.width
                        property bool isHeader: modelData.startsWith("<i>")
                        property string cleanText: isHeader ? modelData.replace(/<\/?i>/g, "") : modelData

                        Item {
                            width: parent.width
                            height: isHeader && index > 0 ? Theme.spacingS : 0
                        }

                        StyledText {
                            width: parent.width
                            text: parent.cleanText
                            font.pixelSize: parent.isHeader ? Theme.fontSizeMedium : Theme.fontSizeSmall
                            font.weight: parent.isHeader ? Font.Bold : Font.Normal
                            color: parent.isHeader ? Theme.primary : Theme.widgetTextColor
                            textFormat: parent.isHeader ? Text.PlainText : Text.RichText
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            MouseArea {
                width: parent.width
                height: meetRow.implicitHeight + Theme.spacingL
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached(["khal-open-meet"])
                    popout.closePopout()
                }

                Row {
                    id: meetRow
                    anchors.centerIn: parent
                    spacing: Theme.spacingS

                    DankIcon {
                        name: "video_call"
                        size: Theme.iconSize
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: "Join Meet"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    popoutWidth: 350
    popoutHeight: 400
}