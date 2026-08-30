{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    thunar
    thunar-archive-plugin
    thunar-volman
    tumbler
    libmtp
    rar
  ];

  services.gvfs.enable = true;
}
