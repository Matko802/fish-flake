{ lib, ... }:

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

    swapDevices = lib.mkForce [{
      device = "/swapfile";
      size = 6144;
    }];

  };
}
