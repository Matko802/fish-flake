pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
  id: root

  property bool dnd: false
  property var notifications: []
  property var hiddenToasts: []

  property int meaningfulCount: root.notifications.filter(n => n && isMeaningful(n)).length

  function isMeaningful(n) {
    if (!n) return false
    const s = (n.summary || "").trim()
    const b = (n.body || "").trim()
    const im = n.image ? String(n.image) : ""
    return s !== "" || b !== "" || im !== ""
  }

  ListModel { id: popupModel }
  property alias popupModel: popupModel

  NotificationServer {
    id: server
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    imageSupported: true

    onNotification: notif => {
      notif.tracked = true
      if (!root.isMeaningful(notif)) return
      root.notifications = root.notifications.filter(n => n && n.id !== notif.id)
      root.notifications = [notif, ...root.notifications]
      console.log("QS notif", notif.id, notif.summary, "popup before", popupModel.count)
      if ((root.dnd && notif.urgency !== NotificationUrgency.Critical) || ControlState.open || ClockState.open) {
        root.hiddenToasts = [...root.hiddenToasts, notif.id]
        return
      }
      addPopup(notif)
      console.log("QS added popup", notif.id, "count", popupModel.count)
    }
  }

  function addPopup(notif) {
    popupModel.insert(0, {
      notifId: notif.id,
      app: notif.appName || notif.desktopEntry || "notification",
      desktopEntry: notif.desktopEntry || "",
      appName: notif.appName || "",
      appIcon: notif.appIcon || "",
      summary: notif.summary || "",
      body: notif.body || "",
      urgency: notif.urgency ?? 1,
      expireTimeout: notif.expireTimeout ?? 0,
      image: notif.image || ""
    })
  }

  function findPopupIndex(id) {
    for (let i = 0; i < popupModel.count; i++)
      if (popupModel.get(i).notifId === id) return i
    return -1
  }

  function removePopup(id) {
    const i = findPopupIndex(id)
    if (i >= 0) popupModel.remove(i)
    root.hiddenToasts = root.hiddenToasts.filter(x => x !== id)
  }

  function hideToast(id) {
    if (!root.hiddenToasts.includes(id)) root.hiddenToasts = [...root.hiddenToasts, id]
    const i = findPopupIndex(id)
    if (i >= 0) popupModel.remove(i)
  }

  function hideAllPopups() {
    popupModel.clear()
  }

  function dismiss(notif) {
    if (!notif) return
    try { notif.dismiss() } catch (e) {}
    root.notifications = root.notifications.filter(n => n && n.id !== notif.id)
    root.hiddenToasts = root.hiddenToasts.filter(x => x !== notif.id)
    const i = findPopupIndex(notif.id)
    if (i >= 0) popupModel.remove(i)
  }

  function clearAll() {
    root.notifications.forEach(n => { try { n.dismiss() } catch (e) {} })
    root.notifications = []
    root.hiddenToasts = []
    popupModel.clear()
  }

  function getLive(id) {
    return root.notifications.find(n => n && n.id === id) || null
  }

  function setDnd(enabled) {
    root.dnd = enabled
    if (enabled) {
      for (let i = 0; i < popupModel.count; i++) {
        const row = popupModel.get(i)
        const live = root.notifications.find(n => n && n.id === row.notifId)
        if (!(live && live.urgency === NotificationUrgency.Critical))
          root.hiddenToasts = [...root.hiddenToasts, row.notifId]
      }
      popupModel.clear()
    }
  }

  function toggleDnd() { root.setDnd(!root.dnd) }

  Process { id: focusProc; running: false }
  function focusApp(raw) {
    if (!raw) return
    const app = String(raw).replace(/"/g, '\\"')
    focusProc.command = ["sh", "-c",
      "ID=$(niri msg -j windows | tr '}' '\\n' | grep -i '" + app + "' | head -1 | grep -o '\"id\":[0-9]*' | cut -d: -f2)" +
      " && [ -n \"$ID\" ] && niri msg action focus-window --id \"$ID\" 2>/dev/null"
    ]
    focusProc.running = true
  }

  function focusPopup(id) {
    let app = ""
    const i = findPopupIndex(id)
    if (i >= 0) {
      const row = popupModel.get(i)
      app = row.desktopEntry || row.appName
    }
    if (!app) {
      const live = root.notifications.find(n => n && n.id === id)
      if (live) app = live.desktopEntry || live.appName
    }
    focusApp(app)
  }
}
