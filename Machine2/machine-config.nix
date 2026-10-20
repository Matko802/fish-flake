# Laptop configuration
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop";

  boot.kernelPackages = pkgs.linuxPackages;

  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.libinput.enable = true;

  programs.fish.enable = true;

  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  system.stateVersion = "26.05";
}
