{ config, ... }: {
  programs.nushell.enable = true;

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config/nushell 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/nushell/config.nu - - - - ${./config/config.nu}"
  ];
}
