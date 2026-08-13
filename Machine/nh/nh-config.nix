{ ... }: {
  environment.sessionVariables.NH_FLAKE = "/home/matko/fish-flake";

  programs.nh = {
    enable = true;
    flake = "/home/matko/fish-flake";
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 3";
    };
  };
}
