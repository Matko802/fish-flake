{ config, pkgs, ... }:
let
  kittyDir = pkgs.runCommand "kitty-config" {} ''
    mkdir -p $out
    cp ${./kitty.conf} $out/kitty.conf
  '';
in {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/kitty - - - - ${kittyDir}"
  ];
}
