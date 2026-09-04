import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  property string displayUser: Quickshell.env("USER") || ""

  IpcHandler {
    target: "lock"
    function lock() { LockState.locked = true }
  }

  LockContext {
    id: lockContext

    onUnlocked: {
      // Unlock the screen before exiting, or the compositor will display a
      // fallback lock you can't interact with.
      LockState.locked = false;
    }
  }

  WlSessionLock {
    id: lock
    locked: LockState.locked

    surface: Component {
      WlSessionLockSurface {
        id: surf
        color: "#000000"

        // 5-second "grace" after locking: any mouse movement or keypress
        // unlocks without a password, like KDE Plasma's post-lock delay.
        property bool graceActive: false

        Timer {
          id: graceTimer
          interval: 5000
          onTriggered: {
            graceActive = false
            passwordBox.forceActiveFocus()
          }
        }

        Connections {
          target: LockState
          function onLockedChanged() {
            if (LockState.locked) {
              graceActive = true
              graceTimer.restart()
            } else {
              graceActive = false
              graceTimer.stop()
            }
          }
        }

        Keys.onPressed: {
          if (graceActive) LockState.locked = false
        }

        ColumnLayout {
          anchors.centerIn: parent

          spacing: 8
          visible: !graceActive

          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            visible: AvatarState.path !== ""
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96
            width: 96
            height: 96
            radius: 48
            clip: true
            color: "#111111"
            border.color: "#ffffff"
            border.width: 2
            Image {
              anchors.fill: parent
              source: AvatarState.path !== "" ? "file://" + AvatarState.path.split("/").map(encodeURIComponent).join("/") : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              smooth: true
            }
          }

          Text {
            id: clock
            property var date: new Date()
            Layout.alignment: Qt.AlignHCenter

            color: "#ffffff"
            renderType: Text.NativeRendering
            font.pointSize: 72
            font.family: Theme.fontFamily

            // updates the clock every second
            Timer {
              running: true
              repeat: true
              interval: 1000

              onTriggered: clock.date = new Date();
            }

            text: {
              const hours = this.date.getHours().toString().padStart(2, '0');
              const minutes = this.date.getMinutes().toString().padStart(2, '0');
              return `${hours}:${minutes}`;
            }
          }

          Text {
            visible: root.displayUser !== ""
            Layout.alignment: Qt.AlignHCenter

            text: root.displayUser
            color: "#888888"
            font.pixelSize: 14
            font.family: Theme.fontFamily
          }

          TextField {
            id: passwordBox
            Layout.alignment: Qt.AlignHCenter

            implicitWidth: 260
            padding: 10

            color: "#ffffff"
            font.pixelSize: 14
            font.family: Theme.fontFamily
            selectedTextColor: "#000000"
            selectionColor: "#ffffff"

            background: Rectangle {
              color: "#000000"
              border.color: lockContext.showFailure ? "#ff0000" : "#ffffff"
              border.width: 1
            }

            focus: true
            enabled: !lockContext.unlockInProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            // Update the text in the context when the text in the box changes.
            onTextChanged: lockContext.currentText = this.text;

            // Try to unlock when enter is pressed.
            onAccepted: lockContext.tryUnlock();

            // Update the text in the box to match the text in the context.
            // This makes sure multiple monitors have the same text.
            Connections {
              target: lockContext

              function onCurrentTextChanged() {
                passwordBox.text = lockContext.currentText;
              }
            }
          }

          Text {
            visible: lockContext.showFailure
            Layout.alignment: Qt.AlignHCenter

            text: "This Password is Incorrect"
            color: "#ff0000"
            font.pixelSize: 12
            font.family: Theme.fontFamily
          }
        }

        Text {
          visible: graceActive
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          text: "Move your mouse or press any key to unlock"
          color: "#888888"
          font.pixelSize: 13
          font.family: Theme.fontFamily
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          enabled: graceActive
          onPositionChanged: LockState.locked = false
          onPressed: LockState.locked = false
        }
      }
    }
  }
}
