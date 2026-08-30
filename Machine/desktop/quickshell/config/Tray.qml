import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray

Item {
  id: root
  property bool expanded: true
  property bool managePopupOpen: false
  property bool trayMenuOpen: false
  property var activeTrayItem: null
  property var activeTrayAnchor: null
  readonly property color fg: Theme.fg
  readonly property string ff: Theme.fontFamily
  // in-memory pin/hide — persists only for session (adapt to file if you want permanence)
  property var pinnedIds: []
  property var hiddenIds: []
  readonly property var pinnedItems: bucket("pinned")
  readonly property var drawerItems: bucket("drawer")
  readonly property var allItems: bucket("all")
  readonly property int drawerCount: drawerItems.length
  readonly property int trayItemExtent: 18
  readonly property int trayItemGap: 2
  readonly property int trayJoinGap: 4
  readonly property int animationDuration: 600
  property real revealProgress: expanded ? 1 : 0
  readonly property real revealExtent: drawerExtent * revealProgress
  readonly property int drawerExtent: drawerCount > 0 ? drawerCount * trayItemExtent + Math.max(0, drawerCount - 1) * trayItemGap : 0
  // computed widths for layout — mimic Omarchy horizontalTray
  readonly property int drawerBlockWidth: allItems.length > 0 ? expandIcon.implicitWidth + drawerExtent : 0
  readonly property int pinnedW: pinnedRow.implicitWidth

  property var submenuStack: []
  readonly property int submenuDepth: submenuStack.length
  readonly property string currentTitle: submenuDepth > 0 ? submenuStack[submenuDepth - 1].title : ""
  readonly property var currentChildren: submenuDepth > 0 ? submenuStack[submenuDepth - 1].opener.children : trayMenuOpener.children
  property bool menuLevelSettling: false

  Component {
    id: submenuOpenerComponent
    QsMenuOpener {}
  }
  Timer {
    id: menuLevelSettleTimer
    interval: 250
    onTriggered: root.menuLevelSettling = false
  }
  function settleMenuLevel() {
    menuLevelSettling = true
    menuLevelSettleTimer.restart()
  }
  function resetTrayMenu() {
    menuLevelSettling = false
    menuLevelSettleTimer.stop()
    trayMenuFlick.contentY = 0
    var openers = submenuStack
    submenuStack = []
    for (var i = openers.length - 1; i >= 0; i--) openers[i].opener.destroy()
  }
  function enterSubmenu(entry, title) {
    var opener = submenuOpenerComponent.createObject(root, { menu: entry })
    if (!opener) return
    var stack = submenuStack.slice()
    stack.push({ opener: opener, title: title })
    submenuStack = stack
    settleMenuLevel()
  }
  function leaveSubmenu() {
    if (submenuStack.length === 0) return
    var stack = submenuStack.slice()
    var top = stack.pop()
    submenuStack = stack
    top.opener.destroy()
    settleMenuLevel()
  }
  function closePopups() {
    managePopupOpen = false
    trayMenuOpen = false
  }
  function openTrayMenu(item, anchorItem, mouse) {
    if (!item || !item.menu) {
      var point = anchorItem.QsWindow.contentItem.mapFromItem(anchorItem, mouse.x, mouse.y)
      item.display(anchorItem.QsWindow.window, point.x, point.y)
      return
    }
    managePopupOpen = false
    resetTrayMenu()
    activeTrayItem = item
    activeTrayAnchor = anchorItem
    trayMenuOpen = true
  }
  function trayIconSource(icon) {
    return String(icon || "")
  }
  function iconIsSymbolic(icon) {
    var name = String(icon || "").split("?")[0]
    return name.slice(-9) === "-symbolic"
  }
  function trayTooltip(item) {
    return item.tooltipTitle || item.title || item.id || ""
  }
  function classifyItem(item) {
    var iid = String(item.id || "")
    if (hiddenIds.indexOf(iid) !== -1) return "hidden"
    if (pinnedIds.indexOf(iid) !== -1) return "pinned"
    return "drawer"
  }
  function bucket(category) {
    var values = SystemTray.items.values
    var result = []
    for (var i = 0; i < values.length; i++) {
      var item = values[i]
      // keep passive hidden like omarchy does — comment out if you want all
      // if (item.status === SystemTray.StatusPassive) continue
      if (category === "all") { result.push(item); continue }
      if (classifyItem(item) === category) result.push(item)
    }
    return result
  }
  function togglePin(iid) {
    var p = pinnedIds.slice(), h = hiddenIds.slice()
    var idx = p.indexOf(iid)
    if (idx !== -1) p.splice(idx, 1)
    else {
      p.push(iid)
      var hi = h.indexOf(iid)
      if (hi !== -1) h.splice(hi, 1)
    }
    pinnedIds = p
    hiddenIds = h
  }
  function toggleHide(iid) {
    var p = pinnedIds.slice(), h = hiddenIds.slice()
    var idx = h.indexOf(iid)
    if (idx !== -1) h.splice(idx, 1)
    else {
      h.push(iid)
      var pi = p.indexOf(iid)
      if (pi !== -1) p.splice(pi, 1)
    }
    pinnedIds = p
    hiddenIds = h
  }

  visible: pinnedItems.length > 0 || drawerCount > 0
  clip: false
  implicitWidth: drawerBlockWidth + pinnedW
  implicitHeight: 30

  Behavior on revealProgress {
    NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic }
  }

  // ====== horizontal tray (fish is always horizontal top bar) ======
  Item {
    id: drawerArea
    x: 0
    width: root.drawerBlockWidth
    height: 30
    visible: root.allItems.length > 0


    // chevron — slides left as drawer opens
    Rectangle {
      id: expandIcon
      width: 18
      height: 18
      x: root.drawerExtent - root.revealExtent
      anchors.verticalCenter: parent.verticalCenter
      color: expandMa.containsMouse ? Theme.fg : "transparent"
      border.color: expandMa.containsMouse ? Theme.outline : "transparent"
      border.width: 1
      Text {
        anchors.centerIn: parent
        text: "\uf053"
        color: expandMa.containsMouse ? Theme.bg : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }
      MouseArea {
        id: expandMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
          if (mouse.button === Qt.RightButton) {
            root.trayMenuOpen = false
            root.managePopupOpen = !root.managePopupOpen
          } else root.expanded = !root.expanded
        }
      }
    }

    Item {
      id: trayClip
      x: expandIcon.width
      anchors.verticalCenter: parent.verticalCenter
      width: root.drawerExtent
      height: 30
      clip: true
      Row {
        id: trayIcons
        x: root.drawerExtent - root.revealExtent
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.trayItemGap
        Repeater {
          model: root.drawerItems
          delegate: TrayItem {}
        }
      }
    }
  }

  Row {
    id: pinnedRow
    x: drawerArea.x + root.drawerBlockWidth
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.trayItemGap
    leftPadding: root.pinnedItems.length > 0 && root.allItems.length > 0 ? root.trayJoinGap : 0
    Repeater {
      model: root.pinnedItems
      delegate: TrayItem {}
    }
  }

  // ====== manage popup (pin/hide) ======
  PopupWindow {
    id: managePopupWin
    visible: root.managePopupOpen
    color: "transparent"
    implicitWidth: 320
    implicitHeight: manageColumn.implicitHeight + 16
    anchor {
      id: manageAnchor
      window: root.QsWindow.window
      edges: Edges.Top | Edges.Left
      gravity: Edges.Top | Edges.Left
      adjustment: PopupAdjustment.Slide
      rect.width: 1
      rect.height: 1
      onAnchoring: {
        var target = root
        if (!target || !target.QsWindow.window) return
        var w = managePopupWin.implicitWidth
        var win = target.QsWindow.window
        var lx = target.width / 2 - w / 2
        var ly = target.height + 4
        var pt = win.contentItem.mapFromItem(target, lx, ly)
        pt.x = Math.max(4, Math.min(pt.x, win.width - w - 4))
        manageAnchor.rect.x = Math.round(pt.x)
        manageAnchor.rect.y = Math.round(pt.y)
      }
    }
    Rectangle {
      anchors.fill: parent
      color: Theme.bg
      border.color: Theme.outline
      border.width: 1
      Column {
        id: manageColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8
        Text {
          text: "Tray icons"
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }
        Text {
          text: "Pinned icons stay visible. Hidden icons never show."
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 9
          wrapMode: Text.WordWrap
          width: parent.width
        }
        Text {
          visible: root.allItems.length === 0
          text: "No tray items."
          color: Theme.muted2
          font.family: Theme.fontFamily
          font.pixelSize: 11
          font.italic: true
        }
        Repeater {
          model: root.allItems
          delegate: Item {
            id: rowRoot
            required property var modelData
            required property int index
            width: manageColumn.width
            implicitHeight: 28
            readonly property string itemId: String(modelData.id || "")
            readonly property string displayName: {
              var t = String(modelData.title || "").trim()
              if (t) return t
              var tt = String(modelData.tooltipTitle || "").trim()
              if (tt) return tt
              var id = String(modelData.id || "")
              var slash = id.lastIndexOf("/")
              return slash !== -1 ? id.substring(slash + 1) : (id || "Unknown")
            }
            readonly property bool isPinned: root.pinnedIds.indexOf(itemId) !== -1
            readonly property bool isHidden: root.hiddenIds.indexOf(itemId) !== -1

            TrayIcon {
              id: rowIcon
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              width: 16; height: 16
              icon: rowRoot.modelData.icon
            }
            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: rowIcon.right
              anchors.leftMargin: 10
              anchors.right: rowHideBtn.left
              anchors.rightMargin: 8
              text: rowRoot.displayName
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
            }
            Rectangle {
              id: rowPinBtn
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: parent.right
              implicitWidth: pinTxt.implicitWidth + 16
              implicitHeight: 20
              color: pinMa.containsMouse ? Theme.fg : "transparent"
              border.color: Theme.outline
              border.width: 1
              Text { id: pinTxt; anchors.centerIn: parent; text: rowRoot.isPinned ? "Unpin" : "Pin"; color: pinMa.containsMouse ? Theme.bg : Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 10 }
              MouseArea { id: pinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePin(rowRoot.itemId) }
            }
            Rectangle {
              id: rowHideBtn
              anchors.verticalCenter: parent.verticalCenter
              anchors.right: rowPinBtn.left
              anchors.rightMargin: 6
              implicitWidth: hideTxt.implicitWidth + 16
              implicitHeight: 20
              color: hideMa.containsMouse ? Theme.fg : "transparent"
              border.color: Theme.outline
              border.width: 1
              Text { id: hideTxt; anchors.centerIn: parent; text: rowRoot.isHidden ? "Show" : "Hide"; color: hideMa.containsMouse ? Theme.bg : Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 10 }
              MouseArea { id: hideMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleHide(rowRoot.itemId) }
            }
          }
        }
      }
    }
  }

  // ====== tray menu popup (QsMenuOpener + drill-down) ======
  QsMenuOpener {
    id: trayMenuOpener
    menu: root.activeTrayItem ? root.activeTrayItem.menu : null
  }
  PopupWindow {
    id: trayMenuPopupWin
    visible: root.trayMenuOpen
    color: "transparent"
    implicitWidth: 232
    // height will be fitted to content up to 420
    implicitHeight: Math.min(420, menuHeader.visible ? menuHeader.implicitHeight + 16 + trayMenuColumn.implicitHeight : 16 + trayMenuColumn.implicitHeight)
    anchor {
      id: trayMenuAnchor
      window: root.QsWindow.window
      edges: Edges.Top | Edges.Left
      gravity: Edges.Top | Edges.Left
      adjustment: PopupAdjustment.Slide
      rect.width: 1
      rect.height: 1
      onAnchoring: {
        var target = root.activeTrayAnchor ? root.activeTrayAnchor : root
        if (!target || !target.QsWindow.window) return
        var w = trayMenuPopupWin.implicitWidth
        var win = target.QsWindow.window
        var lx = target.width / 2 - w / 2
        var ly = target.height + 4
        var pt = win.contentItem.mapFromItem(target, lx, ly)
        pt.x = Math.max(4, Math.min(pt.x, win.width - w - 4))
        trayMenuAnchor.rect.x = Math.round(pt.x)
        trayMenuAnchor.rect.y = Math.round(pt.y)
      }
    }
    onVisibleChanged: if (!visible) root.resetTrayMenu()

    Rectangle {
      id: trayMenuCard
      anchors.fill: parent
      color: Theme.bg
      border.color: Qt.rgba(1,1,1,0.45)
      border.width: 1
      opacity: trayMenuPopupWin.visible ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

      Column {
        id: trayMenuLayout
        anchors.fill: parent
        anchors.margins: 8
        spacing: 0

        Column {
          id: menuHeader
          visible: root.submenuDepth > 0
          width: parent.width
          spacing: 0
          Item {
            id: menuBackRow
            width: parent.width
            implicitHeight: 30
            Rectangle {
              anchors.fill: parent
              color: backMouse.containsMouse ? "#222222" : "transparent"
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              width: 22
              horizontalAlignment: Text.AlignHCenter
              text: "\u2039"
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 11
            }
            Text {
              textFormat: Text.PlainText
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: 28
              anchors.right: parent.right
              anchors.rightMargin: 10
              text: root.currentTitle
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
            }
            MouseArea {
              id: backMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.menuLevelSettling) return
                trayMenuFlick.contentY = 0
                root.leaveSubmenu()
              }
            }
          }
          Item {
            width: parent.width
            implicitHeight: 11
            Rectangle {
              anchors.left: parent.left; anchors.leftMargin: 10
              anchors.right: parent.right; anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              height: 1
              color: Theme.border
              opacity: 0.45
            }
          }
        }

        Flickable {
          id: trayMenuFlick
          width: parent.width
          height: parent.height - (menuHeader.visible ? menuHeader.implicitHeight : 0)
          contentWidth: width
          contentHeight: trayMenuColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height
          ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
          Column {
            id: trayMenuColumn
            width: trayMenuFlick.width
            spacing: 0
            Repeater {
              model: root.currentChildren
              delegate: Item {
                id: menuRow
                required property var modelData
                required property int index
                readonly property string rowText: String(modelData.text || "")
                readonly property string activeTitle: root.activeTrayItem ? String(root.activeTrayItem.title || root.activeTrayItem.id || "") : ""
                readonly property bool atRoot: root.submenuDepth === 0
                readonly property bool rootTitleEntry: atRoot && index === 0 && modelData.hasChildren && rowText.toLowerCase() === activeTitle.toLowerCase()
                readonly property bool leadingSeparator: atRoot && modelData.isSeparator && index <= 1
                readonly property bool hiddenRow: rootTitleEntry || leadingSeparator
                visible: !hiddenRow
                width: trayMenuColumn.width
                implicitHeight: hiddenRow ? 0 : (modelData.isSeparator ? 11 : 30)
                opacity: modelData.enabled ? 1.0 : 0.45
                Rectangle {
                  visible: menuRow.modelData.isSeparator
                  anchors.left: parent.left; anchors.leftMargin: 10
                  anchors.right: parent.right; anchors.rightMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  height: 1; color: Theme.border; opacity: 0.45
                }
                Rectangle {
                  visible: !menuRow.modelData.isSeparator
                  anchors.fill: parent
                  color: rowMouse.containsMouse && menuRow.modelData.enabled ? "#1a1a1a" : "transparent"
                }
                Text {
                  textFormat: Text.PlainText
                  visible: !menuRow.modelData.isSeparator && menuRow.modelData.buttonType !== QsMenuButtonType.None
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  width: 22
                  horizontalAlignment: Text.AlignHCenter
                  text: menuRow.modelData.checkState === Qt.Checked ? "\u2713" : ""
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }
                Image {
                  id: menuIcon
                  visible: !menuRow.modelData.isSeparator && String(menuRow.modelData.icon || "") !== ""
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: 24
                  width: 16; height: 16
                  fillMode: Image.PreserveAspectFit
                  sourceSize.width: width * Screen.devicePixelRatio
                  sourceSize.height: height * Screen.devicePixelRatio
                  source: menuRow.modelData.icon
                }
                Text {
                  textFormat: Text.PlainText
                  visible: !menuRow.modelData.isSeparator
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.leftMargin: menuIcon.visible ? 46 : 28
                  anchors.right: submenuGlyph.left
                  anchors.rightMargin: 8
                  text: menuRow.rowText
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  elide: Text.ElideRight
                }
                Text {
                  id: submenuGlyph
                  visible: !menuRow.modelData.isSeparator && menuRow.modelData.hasChildren
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.right: parent.right
                  anchors.rightMargin: 10
                  text: "\u203a"
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }
                MouseArea {
                  id: rowMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: !menuRow.modelData.isSeparator && menuRow.modelData.enabled
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: {
                    if (root.menuLevelSettling) return
                    if (menuRow.modelData.hasChildren) {
                      trayMenuFlick.contentY = 0
                      root.enterSubmenu(menuRow.modelData, menuRow.rowText)
                    } else {
                      menuRow.modelData.triggered()
                      root.closePopups()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  component TrayIcon: Item {
    id: trayIconRoot
    required property var icon
    readonly property bool symbolic: root.iconIsSymbolic(icon)
    Image {
      id: trayIconImage
      anchors.fill: parent
      fillMode: Image.PreserveAspectFit
      sourceSize.width: Math.round(Math.min(width, height) * Screen.devicePixelRatio)
      sourceSize.height: Math.round(Math.min(width, height) * Screen.devicePixelRatio)
      source: root.trayIconSource(trayIconRoot.icon)
      visible: !trayIconRoot.symbolic
      // layer.enabled when symbolic so MultiEffect can sample
      layer.enabled: trayIconRoot.symbolic
    }
    MultiEffect {
      anchors.fill: trayIconImage
      source: trayIconImage
      visible: trayIconRoot.symbolic
      colorization: 1.0
      colorizationColor: Theme.fg
    }
  }

  component TrayItem: Item {
    id: trayItemRoot
    required property var modelData
    visible: true
    implicitWidth: root.trayItemExtent
    implicitHeight: root.trayItemExtent
    function displayMenu(mouse) {
      root.openTrayMenu(trayItemRoot.modelData, trayItemRoot, mouse)
    }
    TrayIcon {
      anchors.centerIn: parent
      width: 12; height: 12
      icon: trayItemRoot.modelData.icon
    }
    MouseArea {
      id: mouseArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onPressed: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          trayItemRoot.displayMenu(mouse)
          mouse.accepted = true
        }
      }
      onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton) {
          mouse.accepted = true
        } else if (mouse.button === Qt.MiddleButton) {
          trayItemRoot.modelData.secondaryActivate()
        } else if (trayItemRoot.modelData.onlyMenu) {
          trayItemRoot.displayMenu(mouse)
        } else {
          trayItemRoot.modelData.activate()
        }
      }
      onWheel: function(wheel) {
        trayItemRoot.modelData.scroll(wheel.angleDelta.y, false)
      }
    }
  }
}
