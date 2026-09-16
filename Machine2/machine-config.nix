# Laptop configuration
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.xserver.libinput.enable = true;

  programs.nushell.enable = true;

  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.nushell;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  system.stateVersion = "26.05";
}
