import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string eventText: "No events"
    property string agendaText: ""
    property var agendaLines: []

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
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.eventText
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, 300)
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "calendar_today"
                size: root.iconSize
                color: Theme.primary
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
                            color: parent.isHeader ? Theme.primary : Theme.surfaceText
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
