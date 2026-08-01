{ pkgs, ... }: {
  home.packages = [ pkgs.hypridle ];
  xdg.configFile."hypridle/hypridle.conf" = {
    source = ./hypridle.conf;
    force = true;
  };
}
