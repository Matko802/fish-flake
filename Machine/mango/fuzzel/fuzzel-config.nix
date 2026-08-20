{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.fuzzel ];

  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/fuzzel/fuzzel.ini - - - - ${./fuzzel.ini}"
  ];
}
