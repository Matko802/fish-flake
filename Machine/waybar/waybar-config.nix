{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.waybar ];
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/waybar - - - - ${./config}"
  ];
}
