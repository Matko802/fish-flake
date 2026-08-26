pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
  id: root

  property bool dnd: false
  // Live Notification objects, kept for history + action invocation.
  property var notifications: []
  property var hiddenToasts: []

  // The only model the toast stack binds to. Incremental insert/remove means
  // a new toast adds one delegate without recreating the others — so existing
  // cards never re-run their entrance animation.
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

  // Called by a card after its dismiss animation finishes.
  // Keeps the entry in `notifications` so history doesn't vanish.
  function removePopup(id) {
    const i = findPopupIndex(id)
    if (i >= 0) popupModel.remove(i)
    root.hiddenToasts = root.hiddenToasts.filter(x => x !== id)
  }

  // Hide from the toast stack but keep in history (quick settings open, dnd).
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

  // ---- mango WM focus ---------------------------------------------------
  Process { id: focusProc; running: false }
  function focusApp(raw) {
    if (!raw) return
    const app = String(raw).replace(/"/g, '\\"')
    const cmd = 'app="' + app + '"; id=$(mmsg get all-clients 2>/dev/null | python3 -c "import json,sys; a=sys.argv[1].lower(); d=json.load(sys.stdin); cs=d.get(\'clients\',[]); m=[c for c in cs if a==c.get(\'appid\',\'\').lower() or a in c.get(\'appid\',\'\').lower() or a in c.get(\'title\',\'\').lower()]; print(m[0][\'id\'] if m else \'\')" "$app" 2>/dev/null); [ -n "$id" ] && mmsg dispatch focusid client,$id 2>/dev/null || true'
    focusProc.command = ["bash", "-c", cmd]
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
