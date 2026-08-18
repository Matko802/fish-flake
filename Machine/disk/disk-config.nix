{ config, lib, ... }:

let
  cfg = config.services.btrfsOptimizations;
in
{
  options.services.btrfsOptimizations = {
    enable = lib.mkEnableOption "automatic Btrfs mount optimizations (noatime, compress=zstd)";
  };

  config = {
    services.btrfsOptimizations.enable = true;

    fileSystems."/" = {
      options = [ "noatime" "compress=zstd" ];
    };
    fileSystems."/home" = {
      options = [ "subvol=home" "noatime" "compress=zstd" ];
    };
    fileSystems."/nix" = {
      options = [ "subvol=nix" "noatime" "compress=zstd" ];
    };

    swapDevices = [{
      device = "/swapfile";
      size = 6144; # 6 GB
    }];

    zramSwap = {
      enable = true;
      memoryMax = 2 * 1024 * 1024 * 1024; # 2 GB
    };
  };
}