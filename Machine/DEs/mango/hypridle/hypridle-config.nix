{ pkgs, ... }: {
  home.packages = [ pkgs.hypridle ];
  xdg.configFile."hypr/hypridle.conf" = {
    source = ./hypridle.conf;
    force = true;
  };
}
