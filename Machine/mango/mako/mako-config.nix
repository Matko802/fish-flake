{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.mako ];
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/mako/config - - - - ${./config/config}"
  ];
}
