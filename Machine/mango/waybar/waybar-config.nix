{ config, pkgs, ... }:
let
  waybarDir = pkgs.runCommand "waybar-config" {} ''
    mkdir -p $out
    cp ${./config/style.css} $out/style.css
    cp ${./config/config.jsonc} $out/config.jsonc
  '';
in {
  environment.systemPackages = [ pkgs.waybar ];
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/waybar - - - - ${waybarDir}"
  ];
}
