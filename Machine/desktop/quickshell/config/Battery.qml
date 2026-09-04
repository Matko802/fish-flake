import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Standalone battery icon-name provider. Not currently instantiated; Bar.qml
// renders the battery inline. Keep in sync if wired up later.
Item {
  readonly property string batName: {
    try {
      const dev = UPower.displayDevice
      if (!dev || !dev.ready || !dev.isLaptopBattery)
        return ""
      const p = Math.max(0, Math.min(100, Math.round(dev.percentage * 100)))
      const lv = Math.floor(p / 10) * 10
      if (dev.state === UPowerDeviceState.Charging && lv < 100)
        return "bat-" + lv + "-chg"
      if (dev.state === UPowerDeviceState.FullyCharged)
        return "bat-charged"
      return "bat-" + lv
    } catch (e) {
      return ""
    }
  }
}
