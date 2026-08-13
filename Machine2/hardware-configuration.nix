# Laptop hardware config.
# Generate the real one on the laptop with:  nixos-generate-config --root /mnt/nixos
# then copy the generated fileSystems / swapDevices here.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # TODO: replace with the laptop's real root filesystem
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
      fsType = "btrfs";
      options = [ "noatime" "compress=zstd" ];
    };

  # TODO: add the laptop's other mounts (boot, /home, /nix, ...)

  # TODO: add the laptop's swap device
  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
