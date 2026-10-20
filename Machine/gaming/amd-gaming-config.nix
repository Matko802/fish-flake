{ pkgs, lib, ... }:
{
  hardware.amdgpu.overdrive.enable = true;
  services.lact.enable = true;
  users.users."matko".extraGroups = [ "gamemode" ];
  environment.systemPackages = with pkgs; [
    lact
  ];
}
