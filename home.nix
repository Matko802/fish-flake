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
    ./Machine/waybar/waybar-config.nix
    ./Machine/DEs/hypr/hypr/hypr-config.nix
    ./Machine/DEs/hypr/ironbar/ironbar-config.nix
    ./Machine/DEs/hypr/mako/mako-config.nix
    ./Machine/DEs/hypr/awww/awww-config.nix
    ./Machine/DEs/hypr/bemoji/bemoji-config.nix
    ./Machine/DEs/hypr/cliphist/cliphist-config.nix
    ./Machine/DEs/hypr/fuzzel/fuzzel-config.nix
    ./Machine/DEs/hypr/hypridle/hypridle-config.nix
    ./Machine/DEs/hypr/hyprlock/hyprlock-config.nix
    ./Machine/DEs/hypr/hyprpicker/hyprpicker-config.nix
    ./Machine/DEs/hypr/hyprpolkitagent/hyprpolkitagent-config.nix
    ./Machine/DEs/hypr/hyprshot/hyprshot-config.nix
    ./Machine/DEs/hypr/hyprshutdown/hyprshutdown-config.nix
    ./Machine/DEs/hypr/libnotify/libnotify-config.nix
    ./Machine/DEs/hypr/playerctl/playerctl-config.nix
    ./Machine/DEs/hypr/satty/satty-config.nix
    ./Machine/DEs/hypr/waypaper/waypaper-config.nix
    ./Machine/DEs/hypr/wl-clipboard/wl-clipboard-config.nix
  ];

  home.username = "matko";
  home.homeDirectory = "/home/matko";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
