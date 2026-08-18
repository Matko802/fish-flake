{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "L+ ${config.users.users.matko.home}/.config/helix - - - - ${./config}"
  ];

  environment.systemPackages = with pkgs; [
    helix
  ];
}
