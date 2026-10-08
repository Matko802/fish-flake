{ inputs, pkgs, config, lib, ... }:

let
  sharkSrc = "${inputs.sharkshell}/config";

  countIn = needle: hay: builtins.length (lib.splitString needle hay) - 1;

  replaceOnce = file: old: new:
    assert countIn old file == 1;
    lib.replaceStrings [ old ] [ new ] file;

  braceBalance = s: builtins.stringLength s - builtins.stringLength (lib.replaceStrings [ "{" ] [ "" ] s)
    - (builtins.stringLength s - builtins.stringLength (lib.replaceStrings [ "}" ] [ "" ] s));

  indent16 = s:
    lib.concatStringsSep "\n"
      (map (l: if l == "" then "" else "                " + l) (lib.splitString "\n" s));

  appRows = ''
Text {
  text: "DEFAULT APPLICATIONS"
  color: Theme.muted2
  font.family: root.fontFamily
  font.pixelSize: 9
  font.letterSpacing: 2
}

Repeater {
  model: DefaultApps.rows
  delegate: Rectangle {
    required property var modelData
    required property int index
    Layout.fillWidth: true
    Layout.preferredHeight: 44
    color: Theme.bgAlt
    border.color: root.hoverIdx === -20 - index ? Theme.borderStrong : Theme.border
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
        text: "Change"
        color: root.hoverIdx === -20 - index ? Theme.bg : Theme.fg
        font.family: root.fontFamily
        font.pixelSize: 10
      }
    }
    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onEntered: root.hoverIdx = -20 - index
      onExited: { if (root.hoverIdx === -20 - index) root.hoverIdx = -1 }
      onClicked: DefaultApps.cycle(modelData.cat)
    }
  }
}
'';

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

  smSrc = builtins.readFile "${sharkSrc}/SettingsMenu.qml";
  smAnchor = "              ColumnLayout {\n                id: tab3col";
  smParts = lib.splitString smAnchor smSrc;
  smPatched =
    assert builtins.length smParts == 2;
    let
      smHead = builtins.elemAt smParts 0;
      smTail = builtins.elemAt smParts 1;
      smClose = "              }\n";
    in
    assert lib.hasSuffix smClose smHead;
    assert countIn "id: tab2col" smSrc == 1;
    let
      smHead2 = lib.removeSuffix smClose smHead;
      assembled = smHead2 + indent16 appRows + "\n              }\n              "
        + "ColumnLayout {\n                id: tab3col" + smTail;
    in
    assert braceBalance assembled == braceBalance smSrc;
    assert countIn "DEFAULT APPLICATIONS" assembled == 1;
    assert countIn "DefaultApps.cycle" assembled == 1;
    assert countIn "id: tab3col" assembled == 1;
    assembled;

  lcSrc = builtins.readFile "${sharkSrc}/Launcher.qml";
  lcPatched = replaceOnce
    (replaceOnce lcSrc
      "  property var terminalCmd: [\"kitty\", \"-e\"]"
      ("  property var terminalCmd: [\"kitty\", \"-e\"]\n" + launcherConn))
    "    const envTerm = Quickshell.env(\"TERMINAL\")"
    (launcherPref + "    const envTerm = Quickshell.env(\"TERMINAL\")");

  patchedApp = pkgs.writeText "AppTheme.qml" appPatched;
  patchedDyn = pkgs.writeText "DynamicTheme.qml" dynPatched;
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
