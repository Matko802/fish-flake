{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.hyprlock ];
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/hypr/hyprlock.conf - - - - ${./hyprlock.conf}"
  ];
}
