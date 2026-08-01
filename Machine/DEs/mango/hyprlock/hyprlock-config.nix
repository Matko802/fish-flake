{ pkgs, ... }: {
  home.packages = [ pkgs.hyprlock ];
  xdg.configFile."hyprlock/hyprlock.conf" = {
    source = ./hyprlock.conf;
    force = true;
  };
}
