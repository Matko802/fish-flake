{ pkgs, ... }:

{
  # Android in an LXC container (requires Wayland, e.g. Niri).
  # Post-rebuild manual steps:
  #   sudo waydroid init [-s GAPPS -f]
  #   sudo systemctl start waydroid-container
  #   waydroid session start
  #   waydroid show-full-ui
  virtualisation.waydroid = {
    enable = true;
    # Newer kernels use nftables by default; stock waydroid (iptables) breaks networking.
    package = pkgs.waydroid-nftables;
  };

  environment.systemPackages = with pkgs; [
    # Clipboard sharing between host and Waydroid.
    wl-clipboard
    # GUI helper for shared folders (host dir -> Android storage).
    waydroid-helper
    # Robust manual image download: waydroid's built-in urllib downloader
    # can't resume, and SourceForge mirrors often stall mid-download
    # (results in "Downloaded system/vendor image hash doesn't match").
    # Get the CURRENT urls/ids/datetimes from the OTA json first:
    #   curl -sL https://ota.waydro.id/system/lineage/waydroid_x86_64/VANILLA.json | head -c 1500
    #   curl -sL https://ota.waydro.id/vendor/waydroid_x86_64/MAINLINE.json | head -c 800
    # Manual fallback (note: this system uses doas, not sudo):
    #   doas systemctl stop waydroid-container
    #   doas waydroid init -f   # (re)creates /var/lib/waydroid/waydroid.cfg; may fail at download, that's ok
    #   cd /tmp
    #   curl -L --retry 5 --retry-all-errors -C - -o system.zip "<system url from OTA json>"
    #   curl -L --retry 5 --retry-all-errors -C - -o vendor.zip "<vendor url from OTA json>"
    #   echo "<system id>  system.zip" | sha256sum -c
    #   echo "<vendor id>  vendor.zip" | sha256sum -c
    #   doas mkdir -p /var/lib/waydroid/images
    #   doas unzip -o system.zip -d /var/lib/waydroid/images/
    #   doas unzip -o vendor.zip -d /var/lib/waydroid/images/
    #   # Set system_datetime/vendor_datetime in /var/lib/waydroid/waydroid.cfg
    #   # to the OTA datetime values so `init` skips re-download, then:
    #   doas waydroid init
    curl
    unzip
  ];

  # Provides waydroid-mount.service for automatic filesystem setup.
  systemd.packages = [ pkgs.waydroid-helper ];
  systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
}
