import QtQuick
import Qt5Compat.GraphicalEffects
import "Icons.js" as Icons
import "Tabler.js" as Tabler
import "Material.js" as Material


Item {
  id: root

  property string name: ""
  property color color: Theme.fg
  property int size: 16

  implicitWidth: size
  implicitHeight: size

  FontLoader {
    id: materialFont
    source: "fonts/material-icons.ttf"
  }

  FontLoader {
    id: tablerFont
    source: "fonts/noctalia-tabler.ttf"
  }

  readonly property bool useMaterial: Theme.iconTheme === "Material" && Material.has(root.name)
  readonly property bool useMaterialOutlined: root.useMaterial && Material.isOutlined(root.name)

  FontLoader {
    id: outlinedMaterialFont
    source: "fonts/material-icons-outlined.otf"
  }

  Text {
    id: materialText
    anchors.centerIn: parent
    visible: root.useMaterial
    text: Material.resolve(root.name)
    color: root.color
    font.family: root.useMaterialOutlined ? (outlinedMaterialFont.name || "Material Icons Outlined") : (materialFont.name || "Material Icons")
    font.pixelSize: root.size
    font.hintingPreference: Font.PreferNoHinting
    renderType: Text.NativeRendering
  }

  Text {
    id: tablerText
    anchors.centerIn: parent
    visible: !root.useMaterial && Tabler.has(root.name)
    text: Tabler.resolve(root.name)
    color: root.color
    font.family: tablerFont.name || "noctalia-tabler"
    font.pixelSize: root.size
    font.hintingPreference: Font.PreferNoHinting
    renderType: Text.NativeRendering
  }

  Image {
    id: img
    anchors.fill: parent
    visible: !materialText.visible && !tablerText.visible
    fillMode: Image.PreserveAspectFit
    property var list: []
    property int idx: 0
    function start(cands) {
      img.list = cands || []
      img.idx = 0
      img.tryNext()
    }
    function tryNext() {
      if (img.idx < img.list.length) {
        img.source = img.list[img.idx]
        img.sourceSize = Qt.size(root.size * 2, root.size * 2)
      } else if (img.list.length > 0) {
        console.warn("[icon] not found:", root.name, "theme:", Theme.iconTheme)
      }
    }
    onStatusChanged: {
      if (status === Image.Error) {
        img.idx++
        img.tryNext()
      }
    }
  }

  ColorOverlay {
    anchors.fill: parent
    source: img
    color: root.color
    visible: !materialText.visible && !tablerText.visible
  }

  function reload() {
    materialText.text = Material.has(root.name) ? Material.resolve(root.name) : ""
    tablerText.text = Tabler.has(root.name) ? Tabler.resolve(root.name) : ""
    if (!root.useMaterial && !Tabler.has(root.name))
      img.start(Icons.resolve(Theme.iconTheme, root.name))
  }

  onNameChanged: reload()
  onUseMaterialChanged: reload()
  Component.onCompleted: reload()

  Connections {
    target: Theme
    function onIconThemeChanged() {
      root.reload()
    }
  }
}
