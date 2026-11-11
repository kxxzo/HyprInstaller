//@ pragma UseQApplication

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "."

Scope { Variants {
  model: Quickshell.screens
  id: shellroot

  // Configuration
  readonly property string fontFamily: "Maple Mono NF"
  readonly property int fontSize: 17
  readonly property int fontWeight: 700

  property color background: Colors.bg
  property color backgroundStripped: Colors.bgs
  property color accent: Colors.accent

  property color foreground: Colors.fg
  property color dim: Colors.dim

  readonly property int borderSize: 1
  property color borderColor: Colors.surface

  PanelWindow {
    id: panelWindow
    required property var modelData
    screen: modelData
    WlrLayershell.namespace: "quickshell-ui"

    anchors { top: true; left: true; right: true }
    implicitHeight: 40 + shellroot.borderSize + 1 

    color: shellroot.backgroundStripped

    Row {
      id: leftModules

      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
        leftMargin: 10
        bottomMargin: 1 + shellroot.borderSize
      }
      spacing: 5

      Item {
        id: workspacesContainer
        anchors.verticalCenter: parent.verticalCenter
        readonly property int step: 25
        readonly property int dotSize: 10
        readonly property int activeSize: 20
        width: workspaces.count > 0 ? (workspaces.count - 1) * step + activeSize : activeSize
        height: activeSize

        Repeater {
          id: workspaces
          model: 5

          Rectangle {
            required property int index

            x: index * workspacesContainer.step + (workspacesContainer.activeSize - workspacesContainer.dotSize) / 2
            y: (workspacesContainer.activeSize - workspacesContainer.dotSize) / 2
            width: workspacesContainer.dotSize
            height: workspacesContainer.dotSize
            radius: width / 2
	    color: shellroot.borderColor

	    visible: (Hyprland.focusedWorkspace?.id ?? 1) !== (index + 1)
	    opacity: visible ? 1 : 0
    	    Behavior on opacity {
	      NumberAnimation {
		duration: 300;
		easing.type: Easing.OutBack
	      }
    	    }

          }
        }

        Rectangle {
          id: activeIndicator

          x: ((Hyprland.focusedWorkspace?.id ?? 1) - 1) * workspacesContainer.step
          y: 0
          width: workspacesContainer.activeSize
          height: workspacesContainer.activeSize
          radius: width / 2

          color: "transparent"
          border.color: shellroot.accent
          border.width: width / 4

          transformOrigin: Item.Center
          scale: 1.0

          Behavior on x {
            ParallelAnimation {
	      NumberAnimation {
		target: activeIndicator;
		property: "x"; duration: 250;
		easing.type: Easing.OutBack
	      }
              SequentialAnimation {
		NumberAnimation {
		  target: activeIndicator;
		  property: "scale";
		  to: 0.5;
		  duration: 125;
		  easing.type: Easing.InBack
		}
		NumberAnimation {
		  target: activeIndicator;
		  property: "scale";
		  to: 1.0;
		  duration: 125;
		  easing.type: Easing.OutBack
		}
              }
            }
          }
        }
      }
    }

    Row {
      id: rightModules
      anchors {
        top: parent.top
        bottom: parent.bottom
        right: parent.right
        rightMargin: 10
        bottomMargin: 1 + shellroot.borderSize
      }
      spacing: 10

      Repeater {
        id: tray
        model: SystemTray.items

        delegate: Item {
          id: trayIcon
          required property var modelData
          anchors.verticalCenter: parent.verticalCenter
          height: 20
          width: 20

          Image {
            source: modelData.icon
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
            width: 20
            height: 20
          }

          QsMenuOpener {
            id: opener
            menu: modelData.menu
          }

          PopupWindow {
            id: customMenu
            visible: false
            implicitWidth: 300
            implicitHeight: menuColumn.implicitHeight + 8  // small padding for the rounded frame

            anchor.item: trayIcon
            anchor.rect: Qt.rect(0, trayIcon.height, 0, 0)

            color: "transparent"  // PopupWindow itself stays transparent; the Rectangle below draws the visible shape

            Rectangle {
              anchors.fill: parent
              radius: 16
              color: shellroot.background
              clip: true  // clips entry hover/backgrounds to the rounded shape
              Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 15
                color: shellroot.background
                border.color: shellroot.borderColor
                border.width: shellroot.borderSize
                Column {
                  id: menuColumn
                  anchors.centerIn: parent
                  width: parent.width - 8
                  spacing: 2

                  Repeater {
                    model: opener.children
                    delegate: Rectangle {
                      required property var modelData
                      width: menuColumn.width
                      height: 30
                      color: "transparent"
                      radius: 6

                      Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        leftPadding: 10
                        text: modelData.text
                        color: shellroot.foreground
                        font { family: shellroot.fontFamily; pixelSize: shellroot.fontSize }
                      }

                      MouseArea {
                      anchors.fill: parent
                        onClicked: {
                          modelData.triggered()
                          customMenu.visible = false
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          MouseArea {
            id: trayMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
              if (mouse.button === Qt.LeftButton) modelData.activate()
              else if (mouse.button === Qt.RightButton) customMenu.visible = !customMenu.visible
            }
          }
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 40
        implicitWidth: shellroot.borderSize
        color: shellroot.borderColor
      }

      RowLayout {
        id: volume

        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        property var sink: Pipewire.defaultAudioSink

        readonly property bool ready: sink && sink.ready
        readonly property bool muted: ready && sink.audio.muted
        readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

          readonly property string icon: {
          if (!ready) return String.fromCodePoint(0xF0581)
          if (muted) return "Muted 󰸈"
          if (vol === 0) return String.fromCodePoint(0xF0581)
          if (vol < 34) return String.fromCodePoint(0xF057F)
          if (vol < 67) return String.fromCodePoint(0xF0580)

          return String.fromCodePoint(0xF057E)
        }

        Text {
          text: volume.icon
          color: shellroot.foreground
          font {
            family: shellroot.fontFamily
            pixelSize: shellroot.fontSize
            weight: shellroot.fontWeight
          }
        }

        Text {
          text: {
            if (!volume.ready) return "-"
            if (volume.muted) return "muted"
            return volume.vol + "%"
          }
          color: volume.muted ? shellroot.dim : shellroot.foreground
          font {
            family: shellroot.fontFamily
            pixelSize: shellroot.fontSize
            weight: shellroot.fontWeight
          }
        }
        PwObjectTracker {
          objects: [volume.sink]
        }
      }

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 40
        implicitWidth: shellroot.borderSize
        color: shellroot.borderColor
      }

      Text {
        id: clock
        anchors.verticalCenter: parent.verticalCenter

        text: Qt.formatDateTime(time.date, "ddd dd MMM HH:mm")
        color: shellroot.foreground
        font { family: shellroot.fontFamily; pixelSize: shellroot.fontSize; weight: shellroot.fontWeight }

        SystemClock {
          id: time
          precision: SystemClock.Minutes
        }
      }
    }

    Rectangle {
      anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
        bottomMargin: 1
      }
      implicitHeight: shellroot.borderSize
      color: shellroot.borderColor
    }
  }
}}
