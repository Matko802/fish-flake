import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  // Grid wallpaper picker; selecting applies instantly and keeps the window
  // open - only Esc / backdrop click closes.
  property bool opened: false
  property bool entered: false
  property int selIdx: 0
  property int hoverIdx: -1
  property bool imagesLoaded: false
  property string filterText: ""
  property bool editingDir: false
  property string imageDirs: ""
  property string selectedImage: ""
  property var imageArray: []

  readonly property string fontFamily: Theme.fontFamily

  readonly property int cols: 5
  readonly property int cellW: 176
  readonly property int cellH: 110
  readonly property int gridRows: 3
  readonly property int cardMargin: 12

  // Keep the surface mapped briefly after a key-initiated close so the
  // triggering key's press+release both land here instead of the refocused app.
  property bool closePending: false

  function requestClose() {
    if (!root.opened || root.closePending)
      return
    root.closePending = true
    root.entered = false
    closeTimer.restart()
  }

  function forceClose() {
    root.entered = false
    closeTimer.stop()
    root.closePending = false
    root.opened = false
  }

  Timer {
    id: closeTimer
    interval: 400
    onTriggered: {
      root.closePending = false
      root.opened = false
    }
  }

  function toggle() {
    if (root.opened) {
      root.requestClose()
      return
    }
    root.openPicker()
  }

  function openPicker() {
    closeTimer.stop()
    root.closePending = false
    root.editingDir = false
    root.filterText = ""
    dirsFile.reload()
    const custom = dirsFile.text().trim()
    const home = Quickshell.env("HOME")
    root.imageDirs = custom || waypaperIni.text().match(/^folder\s*=\s*(.+)$/m)?.[1]?.trim() || home + "/Pictures/Wallpapers"
    root.selectedImage = WallpaperState.path
    root.imageArray = []
    root.selIdx = 0
    root.hoverIdx = -1
    root.imagesLoaded = false
    root.entered = false
    loadImagesProc.output = ""
    loadImagesProc.running = true
  }

  IpcHandler {
    target: "wallpaper"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  FileView {
    id: dirsFile
    path: Quickshell.env("HOME") + "/.config/quickshell-wallpaper-dirs"
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: waypaperIni
    path: Quickshell.env("HOME") + "/.config/waypaper/config.ini"
    watchChanges: false
    printErrors: false
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function fileUrl(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function nameForPath(path) {
    return path.split("/").pop().replace(/\.[^/.]+$/, "")
  }

  function labelForPath(path) {
    return nameForPath(path).replace(/[-_]+/g, " ").replace(/\b\w/g, m => m.toUpperCase())
  }

  function currentLabel() {
    const e = root.results[root.selIdx]
    return e ? labelForPath(e.filePath) : (root.filterText ? "No matches" : "")
  }

  function itemMatches(filePath) {
    if (!filterText)
      return true
    const needle = filterText.toLowerCase()
    return nameForPath(filePath).toLowerCase().indexOf(needle) !== -1
        || labelForPath(filePath).toLowerCase().indexOf(needle) !== -1
  }

  readonly property var results: {
    const out = []
    for (let i = 0; i < imageArray.length; i++)
      if (itemMatches(imageArray[i].filePath))
        out.push(imageArray[i])
    return out
  }

  onFilterTextChanged: {
    root.selIdx = 0
    root.hoverIdx = -1
  }
  onResultsChanged: {
    if (root.selIdx >= root.results.length)
      root.selIdx = Math.max(0, root.results.length - 1)
    if (root.hoverIdx >= root.results.length)
      root.hoverIdx = -1
  }
  onSelIdxChanged: {
    if (grid)
      grid.positionViewAtIndex(root.selIdx, GridView.Contain)
  }

  function move(step) {
    root.selIdx = Math.max(0, Math.min(root.results.length - 1, root.selIdx + step))
  }

  function apply(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.selectedImage = entry.filePath
    WallpaperState.set(entry.filePath)
  }

  // One <path>\t<thumbnail> row per image; thumbnails cached by md5.
  Process {
    id: loadImagesProc
    property string output: ""
    command: ["bash", "-c",
      "cache_dir=\"$HOME/.cache/quickshell/image-selector\"; mkdir -p \"$cache_dir\";"
      + " while IFS= read -r dir; do [[ -n $dir && -d $dir ]] && find -L \"$dir\" -maxdepth 1 -type f"
      + " \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) -print0;"
      + " done <<< " + shellQuote(root.imageDirs)
      + " | sort -z | while IFS= read -r -d '' image; do"
      + " hash=$(md5sum \"$image\" | cut -d ' ' -f 1); thumb=\"$cache_dir/$hash.jpg\";"
      + " if [[ ! -f $thumb ]]; then"
      + " magick \"$image\"[0] -auto-orient -thumbnail '768x475^' -gravity center -extent 768x475 \"$thumb\" 2>/dev/null || thumb=$image;"
      + " fi; printf '%s\\t%s\\n' \"$image\" \"$thumb\"; done"]
    stdout: SplitParser {
      onRead: function(data) {
        loadImagesProc.output += data + "\n"
      }
    }
    onExited: root.loadRows(output)
  }

  function loadRows(rows) {
    const newImages = []
    const seen = {}
    for (const row of rows.split("\n")) {
      if (!row)
        continue
      const columns = row.split("\t")
      const path = columns[0]
      if (!path)
        continue
      const fileName = path.split("/").pop()
      if (seen[fileName])
        continue
      seen[fileName] = true
      newImages.push({ filePath: path, fileName: fileName, thumbnailPath: columns[1] || path })
    }
    root.imageArray = newImages
    root.imagesLoaded = true
    root.opened = true
    root.entered = true
    grid.forceActiveFocus()
  }

  readonly property int cardWidth: root.cols * root.cellW + root.cardMargin * 2

  PanelWindow {
    visible: root.opened && root.imagesLoaded
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.fill: parent
      color: "transparent"
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    Rectangle {
      id: card
      width: root.cardWidth
      height: layoutCol.implicitHeight + root.cardMargin * 2
      anchors.horizontalCenter: parent.horizontalCenter
      y: (parent.height - height) / 2
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1

      MouseArea { anchors.fill: parent; onClicked: () => {} }

      Column {
        id: layoutCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.cardMargin
        spacing: 8

        Item {
          id: header
          width: parent.width
          height: 14

          Text {
            anchors.left: parent.left
            text: "󰀾"
            color: "#ffffff"
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: 14
          }
        }

        GridView {
          id: grid
          width: parent.width
          height: root.gridRows * root.cellH
          clip: true
          interactive: true
          focus: true
          cellWidth: root.cellW
          cellHeight: root.cellH
          model: root.results

          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              if (root.filterText) {
                root.filterText = ""
              } else {
                root.requestClose()
              }
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.apply(root.selIdx)
              event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
              if (root.filterText.length > 0)
                root.filterText = root.filterText.slice(0, -1)
              event.accepted = true
            } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_D) {
              dirEdit.open()
              event.accepted = true
            } else if (event.key === Qt.Key_Left || (event.key === Qt.Key_Tab && event.modifiers & Qt.ShiftModifier)) {
              root.move(-1)
              event.accepted = true
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
              root.move(1)
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              root.move(-root.cols)
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              root.move(root.cols)
              event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
              root.move(-root.cols * root.gridRows)
              event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
              root.move(root.cols * root.gridRows)
              event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
              root.filterText += event.text
              event.accepted = true
            }
          }

          delegate: Rectangle {
            required property var modelData
            required property int index
            width: grid.cellWidth - 8
            height: grid.cellHeight - 8
            x: 4
            y: 4
            readonly property bool isSel: root.selIdx === index
            readonly property bool isHover: root.hoverIdx === index
            readonly property bool isCurrent: modelData.filePath === root.selectedImage
            color: "transparent"

            Image {
              anchors.fill: parent
              source: root.fileUrl(modelData.thumbnailPath)
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              smooth: true
            }

            // Hover/keyboard selection = white outline; picked wallpaper keeps a white tint.
            Rectangle {
              anchors.fill: parent
              color: isCurrent ? "#59ffffff" : "transparent"
              border.width: isSel || isHover ? 1 : 0
              border.color: "#ffffff"
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { root.hoverIdx = index; root.selIdx = index }
              onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
              onClicked: root.apply(index)
            }
          }

          Text {
            visible: root.results.length === 0
            anchors.centerIn: parent
            text: root.imageArray.length === 0 ? "no images found" : "no matches"
            color: "#888888"
            font.family: root.fontFamily
            font.pointSize: 12
          }
        }

        Text {
          width: parent.width
          visible: root.filterText !== "" && !root.editingDir
          horizontalAlignment: Text.AlignHCenter
          text: "filter: " + root.filterText
          color: "#ffffff"
          opacity: 0.85
          font.family: root.fontFamily
          font.pixelSize: 11
          elide: Text.ElideRight
        }

        Text {
          id: selectedLabel
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.currentLabel().toUpperCase()
          color: "#ffffff"
          font.family: root.fontFamily
          font.pixelSize: 13
          font.letterSpacing: 3
          elide: Text.ElideRight
        }

        // Directory chooser: click the path (or Ctrl+D) to edit it.
        Item {
          width: parent.width
          height: 26
          visible: !root.editingDir

          Rectangle {
            id: dirBar
            anchors.centerIn: parent
            width: Math.min(parent.width, dirRow.implicitWidth + 20)
            height: 26
            color: "transparent"
            border.color: "#333333"
            border.width: 1

            Text {
              id: dirRow
              anchors.centerIn: parent
              width: Math.min(parent.width - 16, implicitWidth)
              elide: Text.ElideMiddle
              text: root.imageDirs.replace(/\n/g, " : ")
              color: "#ffffff"
              opacity: 0.6
              font.family: root.fontFamily
              font.pointSize: 11
              horizontalAlignment: Text.AlignHCenter
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: dirEdit.open()
            }
          }
        }

        Item {
          width: parent.width
          height: 26
          visible: root.editingDir

          Rectangle {
            id: dirEditBox
            anchors.fill: parent
            color: "#000000"
            border.color: "#ffffff"
            border.width: 1

          TextInput {
            id: dirEdit
            anchors.fill: parent
            anchors.margins: 5
            verticalAlignment: TextInput.AlignVCenter
            font.family: root.fontFamily
            font.pointSize: 11
            color: "#ffffff"
            clip: true

            function open() {
              root.editingDir = true
              text = root.imageDirs
              forceActiveFocus()
              cursorPosition = text.length
            }

            function commit() {
              const next = text.trim()
              root.editingDir = false
              if (next === "" || next === root.imageDirs) {
                grid.forceActiveFocus()
                return
              }
              dirsFile.setText(next + "\n")
              root.imageDirs = next
              root.imageArray = []
              root.imagesLoaded = false
              loadImagesProc.output = ""
              loadImagesProc.running = true
              grid.forceActiveFocus()
            }

            Keys.onEscapePressed: {
              root.editingDir = false
              grid.forceActiveFocus()
            }
            Keys.onReturnPressed: commit()
            Keys.onEnterPressed: commit()
            }
          }
        }
      }
    }
  }
}
