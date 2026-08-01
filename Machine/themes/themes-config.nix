# MatkosAmoled themes — installed by home-manager.
#
# GTK theme   → ~/.local/share/themes/MatkosAmoled/   (XDG data, picked up by GTK)
# KVantum     → ~/.config/Kvantum/MatkosAmoled/      (Qt6/5 theming engine)
#
# The kvantum package provides the kvantum-manager binary used to select
# the theme at runtime; kvantum itself reads the theme on startup.
{ pkgs, ... }:
{
  # GTK3 / GTK4 / libadwaita theme — pure-black + cyan accent.
  xdg.dataFile."themes/MatkosAmoled".source = ./config/gtk/MatkosAmoled;

  # KVantum Qt theme — same palette as Qt5/Qt6 apps.
  xdg.configFile."Kvantum/MatkosAmoled".source = ./config/kvantum/MatkosAmoled;

  # Pull kvantum into the user profile so `kvantum-manager` is available
  # and the Kvantum plugin loader library is on the linker path.
  home.packages = with pkgs; [
    kvantum
  ];
}
