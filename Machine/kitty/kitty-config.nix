{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/kitty - - - - ${./config}"
  ];
}
