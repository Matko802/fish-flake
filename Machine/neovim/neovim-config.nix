{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    neovim
    lazygit
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
