{ pkgs, ... }:

{
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    wl-clipboard
    waydroid-helper
    curl
    unzip
  ];

  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
}
