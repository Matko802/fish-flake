{ pkgs, ... }: {
  xdg.dataFile."color-schemes" = {
    source = ./config;
    recursive = true;
  };
}
