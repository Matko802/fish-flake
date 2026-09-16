{ config, pkgs, ... }: {
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;

  environment.systemPackages = with pkgs; [
    wayshot
    slurp
    satty
    wl-clipboard
    xwayland-satellite
    hyprpolkitagent
    playerctl
  ];

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/niri - - - - ${./config}"
  ];
}
