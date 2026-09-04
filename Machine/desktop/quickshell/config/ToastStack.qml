import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Layouts

// Toast stack — Omarchy Quattro pattern: a ListModel fed by NotificationServer
// so a new toast only instantiates one delegate; existing cards keep their
// state and never re-run their entrance animation. Sharp black/white theme.
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

  // Click-through everywhere except the toast column.
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

        // All toasts live 5s, then the whole batch dismisses together.
        readonly property double lifetime: 5000
        property real remaining: 1.0
        readonly property bool ticking: lifetime > 0 && !card.hovered && !ControlState.open && !ClockState.open

        // Only a freshly-created card (a genuinely new notification) starts
        // with a full lifetime. Re-binding summary/body on insert must NOT reset
        // the countdown, otherwise new notifications "un-stop" every visible card.
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

        // Only this new card animates in (set in card's Component.onCompleted);
        // siblings were not recreated, so they stay put.
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

  // Dismiss every visible toast at once (all animate out, then each removes
  // its own row via onDismissed).
  function dismissAllPopups() {
    for (let i = 0; i < rep.count; i++) {
      const s = rep.itemAt(i)
      if (s && s.dismiss) s.dismiss()
    }
  }
}
