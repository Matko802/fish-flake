import QtQuick
import Qt5Compat.GraphicalEffects
import "Icons.js" as Icons
import "Tabler.js" as Tabler

// Runtime-swappable, monochrome-tinted status icon.
// Now supports Noctalia's Tabler icons (noctalia-tabler.ttf) for status icons.
// If the logical name resolves to a Tabler glyph (via Tabler.js Codepoints + Aliases,
// ported from Noctalia's glyph_registry.cpp), it renders as a Text glyph with the
// Tabler font; otherwise it falls back to the SVG theme resolver (Icons.js) as before.

Item {
  id: root

  property string name: ""
  property color color: Theme.fg
  property int size: 16

  implicitWidth: size
  implicitHeight: size

  // Tabler font — same as Noctalia's assets/fonts/noctalia-tabler.ttf
  FontLoader {
    id: tablerFont
    source: "fonts/noctalia-tabler.ttf"
  }

  // Tabler glyph path — visible when name is a Tabler icon
  Text {
    id: tablerText
    anchors.centerIn: parent
    visible: Tabler.has(root.name)
    text: Tabler.resolve(root.name)
    color: root.color
    font.family: tablerFont.name || "noctalia-tabler"
    font.pixelSize: root.size
    font.hintingPreference: Font.PreferNoHinting
    renderType: Text.NativeRendering
  }

  // SVG fallback path — visible when not a Tabler icon
  Image {
    id: img
    anchors.fill: parent
    visible: !tablerText.visible
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
    visible: !tablerText.visible
  }

  function reload() {
    if (Tabler.has(root.name)) {
      // Tabler path — no SVG resolve needed, just ensure text updates
      tablerText.text = Tabler.resolve(root.name)
    } else {
      img.start(Icons.resolve(Theme.iconTheme, root.name))
    }
  }

  onNameChanged: reload()
  Component.onCompleted: reload()

  Connections {
    target: Theme
    function onIconThemeChanged() {
      // Only SVG path depends on theme; Tabler is theme-independent (monochrome font)
      if (!Tabler.has(root.name)) root.reload()
    }
  }
}
