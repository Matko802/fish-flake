{ config, pkgs, lib, ... }:
let
  qsConfig = pkgs.runCommand "quickshell-config" { src = ./config; } ''
    mkdir -p $out/quickshell
    cp -r $src/. $out/quickshell/
  '';
  # Quickshell's Qt build lacks the webp imageformat plugin; add it so QML
  # Image can decode .webp wallpapers.
  quickshellWrapped = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [ pkgs.quickshell ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/quickshell" \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt6Packages.qtimageformats}/${pkgs.qt6.qtbase.qtPluginPrefix}"
    '';
  };
in {
  environment.systemPackages = [ quickshellWrapped pkgs.upower pkgs.wtype ];
  environment.variables.QUICKSHELL_FONT = config.custom.fontName;
  qt.enable = true;

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/quickshell - - - - ${qsConfig}/quickshell"
  ];
}
