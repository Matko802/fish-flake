{ config, pkgs, ... }:
{
  imports = [
    ./Machine/fastfetch/fastfetch-config.nix
    ./Machine/fish/fish-config.nix
    ./Machine/Starship/starship-config.nix
    ./Machine/kitty/kitty-config.nix
    ./Machine/mpv/mpv-config.nix
    ./Machine/KDE-Colours/kdetheme.nix
    ./Machine/fetch/fetch-config.nix
    ./Machine/hypr/hypr-config.nix
    ./Machine/waybar/waybar-config.nix
    ./Machine/mako/mako-config.nix
    ./Machine/gtk/gtk-config.nix
    ./Machine/qt/qt-config.nix
  ];

  home.username = "matko";
  home.homeDirectory = "/home/matko";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    libnotify
    home-manager
    adw-gtk3
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_PLUGIN_PATH = "/home/matko/.local/lib/qt-5.15.19/plugins:/home/matko/.local/lib/qt-6/plugins";
  };

  programs.home-manager.enable = true;
}
