{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.grim pkgs.slurp ];
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/mango - - - - ${./config}"
  ];
}
