{ config, pkgs, ... }:
let
  qsConfig = pkgs.runCommand "quickshell-config" { src = ./config; } ''
    mkdir -p $out/quickshell
    cp -r $src/. $out/quickshell/
  '';
  # Native output-power QML plugin (wlr-output-power-management-v1 client).
  # Replaces the external `wlopm` utility for turning the display off/on.
  outputPower = pkgs.callPackage ./output-power.nix { };
  quickshellWrapped = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [ pkgs.quickshell ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Install the output-power plugin into quickshell's own QML directory
      mkdir -p "$out/lib/qt-6/qml/Quickshell"
      cp -r ${outputPower}/lib/qt-6/qml/Quickshell/Power "$out/lib/qt-6/qml/Quickshell/Power"
      chmod -R u+w "$out/lib/qt-6/qml/Quickshell/Power"
      wrapProgram "$out/bin/quickshell" \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt6Packages.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}" \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : "$out/lib/qt-6/qml" \
        --prefix QML2_IMPORT_PATH : "$out/lib/qt-6/qml" \
        --prefix QML2_IMPORT_PATH : "/home/matko/.local/share/qmltermwidget" \
        --prefix QML2_IMPORT_PATH : "${pkgs.qt6Packages.qt5compat}/${pkgs.qt6.qtbase.qtQmlPrefix}" \
        --prefix QML_IMPORT_PATH : "$out/lib/qt-6/qml" \
        --prefix QML_IMPORT_PATH : "/home/matko/.local/share/qmltermwidget"
    '';
  };
in {
  environment.systemPackages = with pkgs; [ quickshellWrapped upower wtype ];
  environment.variables.QUICKSHELL_FONT = config.custom.fontName;
  qt.enable = true;

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/quickshell - - - - ${qsConfig}/quickshell"
  ];
}
