{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/fetch/config - - - - ${./config}"
  ];
}
