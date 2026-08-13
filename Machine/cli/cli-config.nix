{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    fd
    ripgrep
    bat
  ];

  programs.fish.shellAbbrs = {
    find = "fd";
    grep = "rg";
    cat = "bat";
  };
}
