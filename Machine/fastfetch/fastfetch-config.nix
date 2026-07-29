{ pkgs, ... }: {
  xdg.configFile."fastfetch" = {
    source = ./config;
    recursive = true;
  };
}
