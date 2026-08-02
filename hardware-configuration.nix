# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b26d52e5-f7c5-4e69-90d7-195f75ed7bfd";
      fsType = "btrfs";
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/b26d52e5-f7c5-4e69-90d7-195f75ed7bfd";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/b26d52e5-f7c5-4e69-90d7-195f75ed7bfd";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C636-5218";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/mnt/ssd" =
    { device = "/dev/disk/by-uuid/5985a5cc-6808-46fa-ac5a-f321e2838c8f";
      fsType = "ext4";
      options = [ "defaults" "noatime" "nofail" ];
    };


  swapDevices =
    [ { device = "/dev/disk/by-uuid/c3c7bc3f-f27d-48ea-8203-d29435a62170"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
