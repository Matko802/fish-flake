{ config, pkgs, ... }: {
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri;

  # Tools used by keybinds/autostart (same set as mango had)
  environment.systemPackages = with pkgs; [
    grim
    slurp
    satty
    wl-clipboard
    xwayland-satellite
    hyprpolkitagent
    playerctl
    # quickshell stays via quickshell-config.nix
  ];

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/niri - - - - ${./config}"
  ];
}
