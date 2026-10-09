{ inputs, pkgs, config, ... }:

let
  origPkg = pkgs.callPackage "${inputs.sharkshell}/packaging.nix" { };
in
{
  environment.systemPackages = with pkgs; [ origPkg.sharkshell upower wtype matugen ];
  environment.variables.QUICKSHELL_FONT = config.custom.fontName;
  qt.enable = true;

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/quickshell - - - - ${origPkg.qsConfig}/quickshell"
    "L+ ${config.users.users.matko.home}/.config/matugen - - - - ${origPkg.matugenConfig}/matugen"
  ];
}
