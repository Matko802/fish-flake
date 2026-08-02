{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.hypridle ];
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/hypr/hypridle.conf - - - - ${./hypridle.conf}"
  ];
}
