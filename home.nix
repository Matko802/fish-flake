{ config, pkgs, ... }:
{
  imports = [
    ./Machine/fastfetch/fastfetch-config.nix
    ./Machine/fish/fish-config.nix
    ./Machine/Starship/starship-config.nix
    ./Machine/kitty/kitty-config.nix
    ./Machine/mpv/mpv-config.nix
    ./Machine/fetch/fetch-config.nix
    ./Machine/DEs/mango/mango-config.nix
    ./Machine/DEs/mango/awww/awww-config.nix
    ./Machine/DEs/mango/bemoji/bemoji-config.nix
    ./Machine/DEs/mango/cliphist/cliphist-config.nix
    ./Machine/DEs/mango/fuzzel/fuzzel-config.nix
    ./Machine/DEs/mango/hypridle/hypridle-config.nix
    ./Machine/DEs/mango/hyprlock/hyprlock-config.nix
    ./Machine/DEs/mango/hyprpicker/hyprpicker-config.nix
    ./Machine/DEs/mango/hyprpolkitagent/hyprpolkitagent-config.nix
    ./Machine/DEs/mango/libnotify/libnotify-config.nix
    ./Machine/DEs/mango/mako/mako-config.nix
    ./Machine/DEs/mango/playerctl/playerctl-config.nix
    ./Machine/DEs/mango/satty/satty-config.nix
    ./Machine/DEs/mango/waypaper/waypaper-config.nix
    ./Machine/DEs/mango/wl-clipboard/wl-clipboard-config.nix
    ./Machine/waybar/waybar-config.nix
  ];

  home.username = "matko";
  home.homeDirectory = "/home/matko";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
