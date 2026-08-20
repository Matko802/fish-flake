{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.hypridle ];
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/hypr 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/hypr/hypridle.conf - - - - ${./hypridle.conf}"
  ];
}
