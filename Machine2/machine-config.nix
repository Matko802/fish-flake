# Laptop configuration
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "laptop"; # TODO: set the laptop's hostname

  # TODO: switch to a different bootloader if needed
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Touchpad support
  services.xserver.libinput.enable = true;

  # Fish shell
  programs.fish.enable = true;

  # Same user as on the PC (shared dotfiles need it)
  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  system.stateVersion = "26.05";

  # TODO: add laptop-specific settings here
  # TODO: import the app/user configs you want (see Machine/machine-config.nix imports)
}
