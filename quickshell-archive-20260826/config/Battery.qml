import QtQuick
import Quickshell
import Quickshell.Services.UPower

Text {
  color: "#ffffff"
  font.pixelSize: 12
  text: {
    try {
      const dev = UPower.displayDevice
      if (!dev || !dev.ready || !dev.isLaptopBattery)
        return ""
      const p = Math.round(dev.percentage * 100)
      const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      let icon
      if (dev.state === UPowerDeviceState.Charging)
        icon = "󰂄"
      else if (dev.state === UPowerDeviceState.FullyCharged)
        icon = ""
      else
        icon = icons[p >= 100 ? 10 : Math.floor(p / 10)]
      return icon + " " + p + "%"
    } catch (e) {
      return ""
    }
  }
}
