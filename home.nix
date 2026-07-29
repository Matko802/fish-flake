{ config, pkgs, ... }:

{
  home.username = "matko";
  home.homeDirectory = "/home/matko";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    libnotify
  ];

  xdg.configFile = {
    "hypr/hyprland.lua".source = ./config/hypr/hyprland.lua;
    "hypr/hyprlock.conf".source = ./config/hypr/hyprlock.conf;
    "hypr/hypridle.conf".source = ./config/hypr/hypridle.conf;
    "hypr/input.lua".source = ./config/hypr/input.lua;
    "hypr/monitors.lua".source = ./config/hypr/monitors.lua;
    "hypr/monitors.conf".source = ./config/hypr/monitors.conf;
    "hypr/power_menu.lua".source = ./config/hypr/power_menu.lua;
    "hypr/volume.sh".source = ./config/hypr/volume.sh;
    "hypr/fuzzel-power.sh".source = ./config/hypr/fuzzel-power.sh;
    "hypr/cliphist-fuzzel-img.sh".source = ./config/hypr/cliphist-fuzzel-img.sh;
    "waybar/config.jsonc".source = ./config/waybar/config.jsonc;
    "waybar/style.css".source = ./config/waybar/style.css;
  };

  programs.home-manager.enable = true;
}
