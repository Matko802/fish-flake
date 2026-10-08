{ inputs, pkgs, config, lib, ... }:

let
  sharkSrc = "${inputs.sharkshell}/config";

  countIn = needle: hay: builtins.length (lib.splitString needle hay) - 1;

  replaceOnce = file: old: new:
    assert countIn old file == 1;
    lib.replaceStrings [ old ] [ new ] file;

  braceBalance = s: builtins.stringLength s - builtins.stringLength (lib.replaceStrings [ "{" ] [ "" ] s)
    - (builtins.stringLength s - builtins.stringLength (lib.replaceStrings [ "}" ] [ "" ] s));

  shiftLines = pre: s:
    lib.concatStringsSep "\n"
      (map (l: if l == "" then "" else pre + l) (lib.splitString "\n" s));

  tabAppsCol = ''
ColumnLayout {
  id: tab5col
  width: pageFlick.width
  spacing: 8
  Repeater {
    model: root.appsItems
    delegate: ColumnLayout {
      required property var modelData
      required property int index
      property string rowCat: modelData.cat
      property int rowIdx: index
      Layout.fillWidth: true
      spacing: 0
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        color: Theme.bgAlt
        border.color: root.hoverIdx === -30 - rowIdx ? Theme.borderStrong : Theme.border
        border.width: 1
        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10
          QIcon { name: modelData.icon; size: 18; color: Theme.muted }
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            spacing: 2
            Text {
              text: modelData.label
              color: Theme.fg
              font.family: root.fontFamily
              font.pixelSize: 11
            }
            Text {
              text: modelData.current
              color: Theme.muted2
              font.family: root.fontFamily
              font.pixelSize: 9
              elide: Text.ElideRight
            }
          }
          Text {
            text: root.expandedApp === rowIdx ? "Hide" : "Change"
            color: root.hoverIdx === -30 - rowIdx ? Theme.bg : Theme.fg
            font.family: root.fontFamily
            font.pixelSize: 10
          }
        }
        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.hoverIdx = -30 - rowIdx
          onExited: { if (root.hoverIdx === -30 - rowIdx) root.hoverIdx = -1 }
          onClicked: root.toggleApp(rowIdx)
        }
      }
      ColumnLayout {
        visible: root.expandedApp === rowIdx
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4
        Repeater {
          model: DefaultApps.optsFor(rowCat)
          delegate: Rectangle {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: DefaultApps.currentIdOf(rowCat) === modelData.id ? Theme.bgAlt : "transparent"
            border.color: root.hoverIdx === -40 - index ? Theme.borderStrong : Theme.border
            border.width: 1
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 10
              QIcon {
                name: "check"
                size: 14
                color: Theme.fg
                visible: DefaultApps.currentIdOf(rowCat) === modelData.id
              }
              Text {
                Layout.fillWidth: true
                text: modelData.name
                color: Theme.fg
                font.family: root.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
              }
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.hoverIdx = -40 - index
              onExited: { if (root.hoverIdx === -40 - index) root.hoverIdx = -1 }
              onClicked: root.chooseApp(rowCat, modelData.id)
            }
          }
        }
        Text {
          visible: DefaultApps.optsFor(rowCat).length === 0
          Layout.fillWidth: true
          text: "None installed"
          color: Theme.muted2
          font.family: root.fontFamily
          font.pixelSize: 10
        }
      }
    }
  }
}
'';

  settingsHelpers = ''
property int expandedApp: -1
readonly property var appsItems: DefaultApps.rows
function toggleApp(i) {
  root.expandedApp = root.expandedApp === i ? -1 : i
}
function chooseApp(cat, id) {
  DefaultApps.setApp(cat, id)
  root.expandedApp = -1
}
'';

  customSection = ''
Text {
  visible: !DynamicTheme.enabled
  text: "CUSTOM COLORS"
  color: Theme.muted2
  font.family: root.fontFamily
  font.pixelSize: 9
  font.letterSpacing: 2
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Accent hue"
  icon: "tune"
  value: CustomTheme.accentH
  text: String(Math.round(CustomTheme.accentH * 360))
  onUserSet: v => CustomTheme.setAccentH(v)
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Accent saturation"
  icon: "tune"
  value: CustomTheme.accentS
  text: String(Math.round(CustomTheme.accentS * 100)) + "%"
  onUserSet: v => CustomTheme.setAccentS(v)
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Accent lightness"
  icon: "tune"
  value: CustomTheme.accentV
  text: String(Math.round(CustomTheme.accentV * 100)) + "%"
  onUserSet: v => CustomTheme.setAccentV(v)
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Background hue"
  icon: "wallpaper"
  value: CustomTheme.bgH
  text: String(Math.round(CustomTheme.bgH * 360))
  onUserSet: v => CustomTheme.setBgH(v)
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Background saturation"
  icon: "wallpaper"
  value: CustomTheme.bgS
  text: String(Math.round(CustomTheme.bgS * 100)) + "%"
  onUserSet: v => CustomTheme.setBgS(v)
}
SettingSlider {
  visible: !DynamicTheme.enabled
  label: "Background lightness"
  icon: "wallpaper"
  value: CustomTheme.bgV
  text: String(Math.round(CustomTheme.bgV * 100)) + "%"
  onUserSet: v => CustomTheme.setBgV(v)
}
Rectangle {
  visible: !DynamicTheme.enabled
  Layout.fillWidth: true
  Layout.preferredHeight: 32
  color: root.hoverIdx === -50 ? Theme.bgAlt : "transparent"
  border.color: root.hoverIdx === -50 ? Theme.borderStrong : Theme.border
  border.width: 1
  Text {
    anchors.centerIn: parent
    text: "Reset custom colors"
    color: Theme.fg
    font.family: root.fontFamily
    font.pixelSize: 11
  }
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onEntered: root.hoverIdx = -50
    onExited: { if (root.hoverIdx === -50) root.hoverIdx = -1 }
    onClicked: CustomTheme.resetDefaults()
  }
}
'';

  dynOffOld = "    } else {\n      root.appsThemed = false\n      root.restoreDefaults()\n      root.resetAppThemes()\n    }";
  dynOffNew = "    } else {\n      root.appsThemed = false\n      CustomTheme.apply()\n    }";

  dynEnsureOld = "  function ensureOutputs() {\n    if (!root.enabled) {\n      root.appsThemed = false\n      root.restoreDefaults()";
  dynEnsureNew = "  function ensureOutputs() {\n    if (!root.enabled) {\n      root.appsThemed = false\n      CustomTheme.apply()";

  dynCacheOld = "    onLoaded: {\n      var t = text().trim()\n      if (t !== \"\" && root.applySchemeText(t)) {";
  dynCacheNew = "    onLoaded: {\n      if (!root.enabled)\n        return\n      var t = text().trim()\n      if (t !== \"\" && root.applySchemeText(t)) {";

  smCustomAnchor = "                SettingSlider {\n                  label: \"Blur\"";

  iniSigOld = "  function settingsIniText(cur, dark) {";
  iniSigNew = "  function settingsIniText(cur, dark, forceTheme) {";
  iniHeadOld = "    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)";
  iniHeadNew = iniHeadOld + "\n    var themeName = (forceTheme !== undefined && forceTheme !== \"\" ? forceTheme : (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"))";
  iniPairsOld = "      [\"gtk-theme-name\", d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"],";
  iniPairsNew = "      [\"gtk-theme-name\", themeName],";
  launcherConn = lib.concatStringsSep "\n" [
    ""
    "  Connections {"
    "    target: DefaultApps"
    "    function onTerminalCmdChanged() {"
    "      if (DefaultApps.hasTerminalChoice && DefaultApps.terminalCmd.length > 0)"
    "        root.terminalCmd = DefaultApps.terminalCmd"
    "    }"
    "  }"
  ];

  launcherPref = lib.concatStringsSep "\n" [
    ""
    "    if (DefaultApps.hasTerminalChoice && DefaultApps.terminalCmd.length > 0) {"
    "      root.terminalCmd = DefaultApps.terminalCmd"
    "      return"
    "    }"
    ""
  ];

  staticQtengineFn = lib.concatStringsSep "\n" [
    "  function staticQtengineJsonText(dark) {"
    "    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)"
    "    var o = {"
    "      theme: {"
    "        colorScheme: d ? \"/usr/share/color-schemes/MatkosAmoled.colors\" : \"/usr/share/color-schemes/MatkosAmoledLight.colors\","
    "        iconTheme: root.iconTheme(d),"
    "        style: \"breeze\","
    "        font: { family: Theme.fontFamily, size: 11, weight: -1 },"
    "        fontFixed: { family: Theme.fontFamily, size: 11, weight: -1 }"
    "      },"
    "      misc: {"
    "        singleClickActivate: false,"
    "        menusHaveIcons: true,"
    "        shortcutsForContextMenus: true"
    "      }"
    "    }"
    "    return JSON.stringify(o)"
    "  }"
  ];

  resetOld = lib.concatStringsSep "\n" [
    "  function reset() {"
    "    resetThemeProc.running = false"
    "    resetThemeProc.running = true"
    "    gtkIniFile3.setText(root.settingsIniText(root.iniText3, true))"
    "    gtkIniFile4.setText(root.settingsIniText(root.iniText4, true))"
    "    overridesFile.setText(root.flatpakOverridesText(true))"
    "    root.dconfPush(true)"
    "  }"
  ];

  resetNew = lib.concatStringsSep "\n" [
    "  function reset() {"
    "    resetThemeProc.running = false"
    "    resetThemeProc.running = true"
    "    qtengineFile.setText(root.staticQtengineJsonText(DynamicTheme.darkMode))"
    "    gtkIniFile3.setText(root.settingsIniText(root.iniText3, DynamicTheme.darkMode))"
    "    gtkIniFile4.setText(root.settingsIniText(root.iniText4, DynamicTheme.darkMode))"
    "    overridesFile.setText(root.flatpakOverridesText(DynamicTheme.darkMode))"
    "    root.dconfPush(DynamicTheme.darkMode)"
    "  }"
  ];

  appSrc = builtins.readFile "${sharkSrc}/AppTheme.qml";
  appPatched =
    replaceOnce
      (replaceOnce
        (replaceOnce
          (replaceOnce
            (replaceOnce
              (replaceOnce appSrc
                "[\"gtk-theme-name\", \"Adwaita\"]"
                "[\"gtk-theme-name\", d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"]")
              "L.push(\"GTK_THEME=Adwaita\")"
              "L.push(\"GTK_THEME=\" + (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"))")
            "\\\"'Adwaita'\\\""
            "\" + \"'\" + (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\") + \"'\" + \"")
          "  function qtengineJsonText() {"
          (staticQtengineFn + "\n  function qtengineJsonText() {"))
        resetOld
        resetNew)
      "    command: [\"bash\", \"-c\", \"rm -f \\\"$HOME/.config/qtengine/config.json\\\" \\\"$HOME/.config/sharkshell/kde-dynamic.colors\\\" \\\"$HOME/.config/gtk-3.0/gtk.css\\\" \\\"$HOME/.config/gtk-4.0/gtk.css\\\"\"]"
      "    command: [\"bash\", \"-c\", \"rm -f \\\"$HOME/.config/sharkshell/kde-dynamic.colors\\\" \\\"$HOME/.config/gtk-3.0/gtk.css\\\" \\\"$HOME/.config/gtk-4.0/gtk.css\\\"\"]";

  dynSrc = builtins.readFile "${sharkSrc}/DynamicTheme.qml";
  dynImport = replaceOnce dynSrc
    "import \"Util.js\" as Util"
    "import \"Util.js\" as Util\nimport \"WallpaperColors.js\" as WallpaperColors";
  dynPatched =
    assert countIn "root.themedKittyColors()" dynImport == 3;
    lib.replaceStrings
      [ "root.themedKittyColors()" ]
      [ "WallpaperColors.buildTerminalTheme(DynColor, root.wallColors, root.roles, root.palettes, root.darkMode)" ]
      dynImport;
  dynOff = replaceOnce dynPatched dynOffOld dynOffNew;
  dynEnsure = replaceOnce dynOff dynEnsureOld dynEnsureNew;
  dynCache = replaceOnce dynEnsure
    "    onLoaded: {\n      var t = text().trim()\n      if (t !== \"\" && root.applySchemeText(t)) {"
    "    onLoaded: {\n      if (!root.enabled)\n        return\n      var t = text().trim()\n      if (t !== \"\" && root.applySchemeText(t)) {";
  dynFinal =
    assert countIn "CustomTheme.apply()" dynCache == 2;
    assert countIn "if (!root.enabled)\n        return\n      var t = text().trim()" dynCache == 1;
    dynCache;

  appF1 = appPatched;
  appF2 = replaceOnce appPatched
    "  function settingsIniText(cur, dark) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)"
    "  function settingsIniText(cur, dark, forceTheme) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)
    var themeName = (forceTheme !== undefined && forceTheme !== \"\" ? forceTheme : (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"))";
  appF3 = replaceOnce appF2
    "      [\"gtk-theme-name\", d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"],"
    "      [\"gtk-theme-name\", themeName],";
  appF4 = replaceOnce appF3
    "  function dconfPush(dark) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)
    var scheme = d ? \"dark\" : \"light\""
    "  function dconfPush(dark, forceTheme, forceScheme) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)
    var scheme = (forceScheme !== undefined && forceScheme !== \"\" ? forceScheme : (d ? \"dark\" : \"light\"))
    var themeName = (forceTheme !== undefined && forceTheme !== \"\" ? forceTheme : (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\"))";
  appF5 = replaceOnce appF4
    "      \"dconf write /org/gnome/desktop/interface/color-scheme \\\"'prefer-\" + scheme + \"'\\\";\""
    "      \"dconf write /org/gnome/desktop/interface/color-scheme \\\"'prefer-\" + scheme + \"'\\\";\"";
  appF6 = replaceOnce appF5
    "      + \" dconf write /org/gnome/desktop/interface/gtk-theme \" + \"'\" + (d ? \"MatkosAmoled\" : \"MatkosAmoledLight\") + \"'\" + \";\""
    "      + \" dconf write /org/gnome/desktop/interface/gtk-theme \" + \"'\" + themeName + \"'\" + \";\"";
  appF7 = replaceOnce appF6
    "  function push() {"
    "  property string gtkFlipTheme: \"\"
  property string gtkFlipScheme: \"\"
  property bool gtkFlipDark: true
  function refreshGtk() {
    var dark = DynamicTheme.darkMode
    var curT = dark ? \"MatkosAmoled\" : \"MatkosAmoledLight\"
    var otherT = dark ? \"MatkosAmoledLight\" : \"MatkosAmoled\"
    var curS = dark ? \"dark\" : \"light\"
    var otherS = dark ? \"light\" : \"dark\"
    root.gtkFlipTheme = curT
    root.gtkFlipScheme = curS
    root.gtkFlipDark = dark
    var ini = root.settingsIniText(root.iniText3, !dark, otherT)
    gtkIniFile3.setText(ini)
    gtkIniFile4.setText(ini)
    root.dconfPush(!dark, otherT, otherS)
    gtkFlipTimer.restart()
  }
  Timer {
    id: gtkFlipTimer
    interval: 400
    repeat: false
    onTriggered: {
      if (DynamicTheme.darkMode !== root.gtkFlipDark)
        return
      var ini = root.settingsIniText(root.iniText3, DynamicTheme.darkMode, root.gtkFlipTheme)
      gtkIniFile3.setText(ini)
      gtkIniFile4.setText(ini)
      root.dconfPush(DynamicTheme.darkMode, root.gtkFlipTheme, root.gtkFlipScheme)
    }
  }
  function push() {";
  appF8 = replaceOnce appF7
    "    overridesFile.setText(root.flatpakOverridesText())
    root.dconfPush()
  }"
    "    overridesFile.setText(root.flatpakOverridesText())
    root.dconfPush()
    if (DynamicTheme.refreshGtkAfterPush) {
      DynamicTheme.refreshGtkAfterPush = false
      root.refreshGtk()
    }
  }";
  appFinal = appF8;

  dynG1 = dynFinal;
  dynG2 = replaceOnce dynFinal
    "  property bool appsThemed: false"
    "  property bool appsThemed: false
  property bool refreshGtkAfterPush: false";
  dynG3 = replaceOnce dynG2
    "      if (!root.appsThemed || WallpaperState.path !== root.schemeWall || root.cachedSchemeMode !== root.schemeMode())
        root.regenerate()"
    "      root.refreshGtkAfterPush = true
      if (!root.appsThemed || WallpaperState.path !== root.schemeWall || root.cachedSchemeMode !== root.schemeMode())
        root.regenerate()";
  dynG4 = replaceOnce dynG3
    "      root.appsThemed = false
      CustomTheme.apply()
    }
  }"
    "      root.appsThemed = false
      CustomTheme.apply()
      AppTheme.refreshGtk()
    }
  }";
  dynFinal2 = dynG4;

  smSrc = builtins.readFile "${sharkSrc}/SettingsMenu.qml";
  smTabs = replaceOnce smSrc
    "    { name: \"Power\", glyph: \"suspend\" }\n  ]"
    "    { name: \"Power\", glyph: \"suspend\" },\n    { name: \"Apps\", glyph: \"settings\" }\n  ]";
  smItems = replaceOnce smTabs
    "  readonly property var currentItems: root.activeTab === 0 ? root.themeItems : (root.activeTab === 3 ? root.visualItems : (root.activeTab === 4 ? [] : root.audioModel))"
    "  readonly property var currentItems: root.activeTab === 0 ? root.themeItems : (root.activeTab === 5 ? root.appsItems : (root.activeTab === 3 ? root.visualItems : (root.activeTab === 4 ? [] : root.audioModel)))";
  smActivate = replaceOnce smItems
    "    } else if (root.activeTab === 3) {"
    "    } else if (root.activeTab === 5) {\n      root.toggleApp(i)\n    } else if (root.activeTab === 3) {";
  smHelpers = replaceOnce smActivate
    "  function activate(i) {"
    (shiftLines "  " settingsHelpers + "\n  function activate(i) {");
  smCollapse = replaceOnce smHelpers
    "  onActiveTabChanged: {\n    root.selIdx = 0\n    root.hoverIdx = -1"
    "  onActiveTabChanged: {\n    root.selIdx = 0\n    root.hoverIdx = -1\n    root.expandedApp = -1";
  smCustom = replaceOnce smCollapse smCustomAnchor
    (shiftLines "                " customSection + "\n" + smCustomAnchor);
  smAnchor = "                  onReset: IdleManager.setSuspendTimeout(IdleManager.suspendDef)\n                }\n              }";
  smParts = lib.splitString smAnchor smCustom;
  smPatched =
    assert builtins.length smParts == 2;
    let
      smHead = builtins.elemAt smParts 0;
      smTail = builtins.elemAt smParts 1;
    in
    assert countIn "id: tab4col" smCollapse == 1;
    let
      assembled = smHead + smAnchor + "\n" + shiftLines "              " tabAppsCol + smTail;
    in
    assert braceBalance assembled == braceBalance smSrc;
    assert countIn "id: tab5col" assembled == 1;
    assert countIn "toggleApp" assembled >= 3;
    assert countIn "chooseApp" assembled == 2;
    assert countIn "expandedApp" assembled >= 4;
    assert countIn "{ name: \"Apps\", glyph: \"settings\" }" assembled == 1;
    assembled;

  lcSrc = builtins.readFile "${sharkSrc}/Launcher.qml";
  lcPatched = replaceOnce
    (replaceOnce lcSrc
      "  property var terminalCmd: [\"kitty\", \"-e\"]"
      ("  property var terminalCmd: [\"kitty\", \"-e\"]\n" + launcherConn))
    "    const envTerm = Quickshell.env(\"TERMINAL\")"
    (launcherPref + "    const envTerm = Quickshell.env(\"TERMINAL\")");

  patchedApp = pkgs.writeText "AppTheme.qml" appFinal;
  patchedDyn = pkgs.writeText "DynamicTheme.qml" dynFinal2;
  patchedMenu = pkgs.writeText "SettingsMenu.qml" smPatched;
  patchedLauncher = pkgs.writeText "Launcher.qml" lcPatched;

  origPkg = pkgs.callPackage "${inputs.sharkshell}/packaging.nix" { };
  qsConfigPatched = pkgs.runCommand "sharkshell-config-patched" { } ''
    mkdir -p $out/quickshell
    cp -r ${inputs.sharkshell}/config/. $out/quickshell/
    chmod -R u+w $out/quickshell
    cp ${./WallpaperColors.js} $out/quickshell/WallpaperColors.js
    cp ${./DefaultApps.qml} $out/quickshell/DefaultApps.qml
    cp ${./DefaultApps.js} $out/quickshell/DefaultApps.js
    cp ${./CustomTheme.qml} $out/quickshell/CustomTheme.qml
    cp ${patchedApp} $out/quickshell/AppTheme.qml
    cp ${patchedDyn} $out/quickshell/DynamicTheme.qml
    cp ${patchedMenu} $out/quickshell/SettingsMenu.qml
    cp ${patchedLauncher} $out/quickshell/Launcher.qml
  '';
in
{
  environment.systemPackages = with pkgs; [ origPkg.sharkshell upower wtype matugen ];
  environment.variables.QUICKSHELL_FONT = config.custom.fontName;
  qt.enable = true;

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/quickshell - - - - ${qsConfigPatched}/quickshell"
    "L+ ${config.users.users.matko.home}/.config/matugen - - - - ${origPkg.matugenConfig}/matugen"
  ];
}
