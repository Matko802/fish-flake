{ inputs, pkgs, config, lib, ... }:

let
  origPkg = pkgs.callPackage "${inputs.sharkshell}/packaging.nix" { };
  qsConfigPatched = pkgs.runCommand "sharkshell-config-patched" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    mkdir -p $out/quickshell
    cp -r ${inputs.sharkshell}/config/. $out/quickshell/
    chmod -R u+w $out/quickshell
    substituteInPlace $out/quickshell/AppTheme.qml \
      --replace-fail '["gtk-theme-name", "Adwaita"]' '["gtk-theme-name", "MatkosAmoled"]' \
      --replace-fail 'L.push("GTK_THEME=Adwaita")' 'L.push("GTK_THEME=MatkosAmoled")' \
      --replace-fail "'Adwaita'" "'MatkosAmoled'"
    cp ${./WallpaperColors.js} $out/quickshell/WallpaperColors.js
    python3 ${./apply-v2.py} $out/quickshell
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
