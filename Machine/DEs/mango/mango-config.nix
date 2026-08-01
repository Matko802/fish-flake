{ pkgs, ... }: {
  home.packages = [ pkgs.grim pkgs.slurp ];
  xdg.configFile."mango" = {
    source = ./config;
    recursive = true;
    force = true;
  };
}
