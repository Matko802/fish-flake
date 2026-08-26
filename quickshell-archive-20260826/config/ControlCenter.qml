import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: ccWindow

  property var targetScreen: null

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  screen: ccWindow.targetScreen
  visible: (ControlState.open && (!ControlState.screen || ControlState.screen === ccWindow.targetScreen))
          || (ClockState.open && (!ClockState.screen || ClockState.screen === ccWindow.targetScreen))

  MouseArea {
    anchors.fill: parent
    onClicked: { ControlState.close(); ClockState.close() }
  }
}
