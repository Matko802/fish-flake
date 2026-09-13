import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts

PanelWindow {
  id: root
  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  visible: NotificationServer.popupModel.count > 0 && !ControlState.open && !ClockState.open

  mask: Region { item: popupColumn }

  Connections {
    target: ControlState
    function onOpenChanged() {
      if (ControlState.open) NotificationServer.hideAllPopups()
    }
  }
  Connections {
    target: ClockState
    function onOpenChanged() {
      if (ClockState.open) NotificationServer.hideAllPopups()
    }
  }

  ColumnLayout {
    id: popupColumn
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: 38
    anchors.rightMargin: 8
    spacing: 8

    Repeater {
      id: rep
      model: NotificationServer.popupModel

      delegate: Item {
        id: cardSlot
        required property int index
        required property int notifId
        required property string app
        required property string appIcon
        required property string summary
        required property string body
        required property int urgency
        required property string image
        required property string desktopEntry
        required property string appName

        Layout.preferredWidth: card.implicitWidth
        Layout.alignment: Qt.AlignRight
        implicitHeight: card.implicitHeight

        readonly property double lifetime: 5000
        property real remaining: 1.0
        readonly property bool ticking: lifetime > 0 && !card.hovered && !ControlState.open && !ClockState.open

        Component.onCompleted: cardSlot.remaining = 1.0

        Timer {
          interval: 50
          repeat: true
          running: cardSlot.ticking
          onTriggered: {
            cardSlot.remaining -= 50 / cardSlot.lifetime
            if (cardSlot.remaining <= 0) {
              cardSlot.remaining = 0
              root.dismissAllPopups()
            }
          }
        }

        function dismiss() { if (!card.dismissing) card.dismiss() }

        NotificationPopup {
          id: card
          anchors.right: parent.right
          notifId: cardSlot.notifId
          app: cardSlot.app
          appIcon: cardSlot.appIcon
          summary: cardSlot.summary
          body: cardSlot.body
          urgency: cardSlot.urgency
          image: cardSlot.image
          desktopEntry: cardSlot.desktopEntry
          appName: cardSlot.appName
          onDismissed: NotificationServer.removePopup(cardSlot.notifId)
          onCloseRequested: NotificationServer.removePopup(cardSlot.notifId)
          onCardClicked: NotificationServer.focusPopup(cardSlot.notifId)
        }
      }
    }
  }

  function dismissAllPopups() {
    for (let i = 0; i < rep.count; i++) {
      const s = rep.itemAt(i)
      if (s && s.dismiss) s.dismiss()
    }
  }
}
