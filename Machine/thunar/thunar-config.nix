{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    libmtp
  ];

  services.gvfs.enable = true;
}
